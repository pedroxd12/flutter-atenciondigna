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

  /// Lista de horarios disponibles del dia para un paquete de estudios.
  /// Espejo de GET /reservaciones/slots.
  Future<Map<String, dynamic>> availableSlots({
    required int branchId,
    required String date,
    required List<int> studyIds,
    int topN = 8,
  }) async {
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/reservaciones/slots',
      queryParameters: {
        'branchId': branchId,
        'date': date,
        'studyIds': studyIds.join(','),
        'topN': topN,
      },
    );
    return res.data ?? const {};
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

  /// Crea una reservacion usando el motor de IA — busca el mejor slot del dia
  /// y devuelve ETA, orden recomendado y nivel de saturacion.
  ///
  /// Espejo de POST /reservaciones/smart en el backend Nest.
  Future<Map<String, dynamic>> smartCreate({
    required String patientId,
    required int branchId,
    required String date,
    required List<int> studyIds,
    String prioridad = 'cita',
    int horaApertura = 7,
    int horaCierre = 20,
    bool confirm = true,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/reservaciones/smart',
      data: {
        'patientId': patientId,
        'branchId': branchId,
        'date': date,
        'studyIds': studyIds,
        'prioridad': prioridad,
        'horaApertura': horaApertura,
        'horaCierre': horaCierre,
        'confirm': confirm,
      },
    );
    return res.data ?? const {};
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
