import '../entities/study_result.dart';

abstract class ResultsRepository {
  Future<List<StudyResult>> getMyResults();
}
