import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/appointments_remote_datasource.dart';
import '../../domain/appointment.dart';

final appointmentsRemoteProvider = Provider<AppointmentsRemoteDataSource>(
  (ref) => AppointmentsRemoteDataSource(ref.watch(apiClientProvider)),
);

class CreateAppointmentParams {
  CreateAppointmentParams({
    required this.branchId,
    required this.date,
    required this.time,
    required this.studyIds,
  });
  final int branchId;
  final String date;
  final String? time;
  final List<int> studyIds;
}

final createAppointmentProvider =
    Provider<Future<Appointment> Function(CreateAppointmentParams)>(
  (ref) => (params) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null) {
      throw Exception('Necesitas iniciar sesion para agendar');
    }
    return ref.read(appointmentsRemoteProvider).create(
          patientId: patientId,
          branchId: params.branchId,
          date: params.date,
          time: params.time,
          studyIds: params.studyIds,
        );
  },
);
