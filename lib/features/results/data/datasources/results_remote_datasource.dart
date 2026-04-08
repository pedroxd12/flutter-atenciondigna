import '../../../../core/network/api_client.dart';
import '../../domain/entities/study_result.dart';

class ResultsRemoteDataSource {
  ResultsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<StudyResult>> getMyResults(String patientId) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/pacientes/$patientId/resultados',
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  StudyResult _fromJson(Map<String, dynamic> j) => StudyResult(
    id: j['id'] as String,
    studyName: j['studyName'] as String,
    branchName: j['branchName'] as String,
    takenAt: DateTime.parse(j['takenAt'] as String),
    readyAt: DateTime.parse(j['readyAt'] as String),
    status: (j['status'] as String) == 'ready'
        ? ResultStatus.ready
        : ResultStatus.processing,
  );
}
