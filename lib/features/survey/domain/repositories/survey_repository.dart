import '../entities/survey_answer.dart';

abstract class SurveyRepository {
  Future<void> submit(List<SurveyAnswer> answers);
}
