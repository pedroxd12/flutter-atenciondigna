import '../../../core/network/api_client.dart';
import '../domain/appointment.dart';

class AppointmentsRemoteDataSource {
  AppointmentsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Appointment> create({
    required String patientId,
    required int branchId,
    required String date, // YYYY-MM-DD
    String? time, // HH:mm
    required List<int> studyIds,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/reservaciones',
      data: {
        'patientId': patientId,
        'branchId': branchId,
        'date': date,
        if (time != null) 'time': time,
        'studyIds': studyIds,
      },
    );
    return _fromJson(res.data!);
  }

  Future<List<Appointment>> listForPatient(String patientId) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/reservaciones/paciente/$patientId',
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  Appointment _fromJson(Map<String, dynamic> j) {
    final ids = (j['studyIds'] as List<dynamic>?) ??
        (j['studies'] as List<dynamic>? ?? const [])
            .map((s) => (s as Map<String, dynamic>)['id'])
            .toList();
    return Appointment(
      id: j['id'].toString(),
      branchId: (j['branchId'] as num).toInt(),
      date: j['date'] as String,
      time: j['time'] as String?,
      studyIds: ids.map((e) => (e as num).toInt()).toList(),
      status: j['status'] as String,
    );
  }
}
