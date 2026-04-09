import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/tracking_remote_datasource.dart';
import '../../domain/entities/tracking_status.dart';

final trackingRemoteProvider = Provider<TrackingRemoteDataSource>(
  (ref) => TrackingRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Provider que hace polling al endpoint de tracking.
/// - 10s cuando el paciente tiene visita activa.
/// - 60s cuando NO tiene visita activa (solo para detectar check-in).
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
    ref.onDispose(() => _timer?.cancel());

    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null) return null;

    // Primera carga.
    final result = await _fetch(patientId);

    // Ajusta intervalo segun si hay visita activa.
    _startPolling(patientId, hasActiveVisit: result?.hasActiveVisit ?? false);

    return result;
  }

  void _startPolling(String patientId, {required bool hasActiveVisit}) {
    _timer?.cancel();
    final interval = hasActiveVisit
        ? const Duration(seconds: 10)
        : const Duration(seconds: 60);
    _timer = Timer.periodic(interval, (_) => _poll(patientId));
  }

  Future<TrackingStatus?> _fetch(String patientId) async {
    final remote = ref.read(trackingRemoteProvider);
    return remote.getTracking(patientId);
  }

  Future<void> _poll(String patientId) async {
    try {
      final result = await _fetch(patientId);
      final wasActive = state.valueOrNull?.hasActiveVisit ?? false;
      final isActive = result?.hasActiveVisit ?? false;
      state = AsyncValue.data(result);
      // Si el estado de visita cambio, reajusta el intervalo de polling.
      if (wasActive != isActive) {
        _startPolling(patientId, hasActiveVisit: isActive);
      }
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
