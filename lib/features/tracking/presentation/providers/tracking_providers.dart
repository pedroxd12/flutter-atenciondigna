import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/tracking_remote_datasource.dart';
import '../../domain/entities/tracking_status.dart';

final trackingRemoteProvider = Provider<TrackingRemoteDataSource>(
  (ref) => TrackingRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Provider que hace polling cada 10 segundos al endpoint de tracking.
/// Se auto-dispone cuando nadie lo observa (autoDispose).
final trackingStatusProvider =
    AutoDisposeAsyncNotifierProvider<TrackingStatusNotifier, TrackingStatus?>(
  TrackingStatusNotifier.new,
);

class TrackingStatusNotifier
    extends AutoDisposeAsyncNotifier<TrackingStatus?> {
  Timer? _timer;

  @override
  Future<TrackingStatus?> build() async {
    // Cancela el timer cuando el provider se dispone.
    ref.onDispose(() => _timer?.cancel());

    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null) return null;

    // Primera carga.
    final result = await _fetch(patientId);

    // Inicia polling cada 10 segundos.
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _poll(patientId);
    });

    return result;
  }

  Future<TrackingStatus?> _fetch(String patientId) async {
    final remote = ref.read(trackingRemoteProvider);
    return remote.getTracking(patientId);
  }

  Future<void> _poll(String patientId) async {
    try {
      final result = await _fetch(patientId);
      state = AsyncValue.data(result);
    } catch (_) {
      // Si falla el polling silencioso, mantenemos el ultimo estado.
    }
  }

  /// Refresco manual (pull-to-refresh).
  Future<void> refresh() async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null) return;
    state = const AsyncValue.loading();
    try {
      final result = await _fetch(patientId);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
