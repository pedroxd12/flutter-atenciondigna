import '../../../../core/network/api_client.dart';
import '../../domain/entities/study.dart';

class StudiesRemoteDataSource {
  StudiesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Study>> getTodaysStudies(String patientId) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/pacientes/$patientId/estudios-hoy',
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  Study _fromJson(Map<String, dynamic> j) => Study(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    estimatedMinutes: (j['estimatedMinutes'] as num).toDouble(),
    requiresPreparation: j['requiresPreparation'] as bool,
    preparations: (j['preparations'] as List<dynamic>).cast<String>(),
    requiresMedicalOrder: j['requiresMedicalOrder'] as bool,
    area: j['area'] as String,
  );
}
