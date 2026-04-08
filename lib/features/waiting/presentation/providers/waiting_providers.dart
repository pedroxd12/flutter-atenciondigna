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
