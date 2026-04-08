import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/waiting_remote_datasource.dart';
import '../../domain/entities/wait_status.dart';

final waitingRemoteProvider = Provider<WaitingRemoteDataSource>(
  (ref) => WaitingRemoteDataSource(ref.watch(apiClientProvider)),
);

final waitStatusStreamProvider = StreamProvider<WaitStatus>((ref) async* {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null) return;
  yield* ref.watch(waitingRemoteProvider).watchStatus(patientId);
});

/// Estado actual (one-shot) — util para pantallas que no necesitan stream.
final waitStatusProvider = FutureProvider<WaitStatus?>((ref) async {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null) return null;
  return ref.watch(waitingRemoteProvider).getCurrent(patientId);
});

/// Cola en vivo del estudio actual del paciente. Vacia si no hay cita.
final waitQueueProvider = FutureProvider<List<QueueItem>>((ref) async {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null) return const [];
  return ref.watch(waitingRemoteProvider).getQueue(patientId);
});
