import '../entities/checkin_pass.dart';

abstract class CheckinRepository {
  Future<CheckinPass> generatePass({
    required String patientId,
    required int branchId,
    required List<int> studyIds,
  });

  Future<ClinicalValidation> validateClinicalRules({
    required List<int> studyIds,
    required bool hasMedicalOrder,
    DateTime? sampleCollectedAt,
  });
}
