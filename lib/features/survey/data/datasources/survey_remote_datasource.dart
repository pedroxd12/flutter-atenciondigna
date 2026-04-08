import '../../../../core/network/api_client.dart';
import '../../domain/entities/survey_answer.dart';

class SurveyRemoteDataSource {
  SurveyRemoteDataSource(this._api);
  final ApiClient _api;

  Future<void> submit({
    required String patientId,
    required int branchId,
    required List<SurveyAnswer> answers,
  }) async {
    await _api.dio.post<dynamic>(
      '/encuestas',
      data: {
        'patientId': patientId,
        'branchId': branchId,
        'answers': answers
            .map((a) => {'questionId': a.questionId, 'rating': a.rating})
            .toList(),
      },
    );
  }
}
