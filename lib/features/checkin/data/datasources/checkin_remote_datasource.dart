import '../../../../core/network/api_client.dart';
import '../../domain/entities/checkin_pass.dart';

class CheckinRemoteDataSource {
  CheckinRemoteDataSource(this._api);
  final ApiClient _api;

  Future<CheckinPass> generatePass({
    required String patientId,
    required int branchId,
    required List<int> studyIds,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/checkin/pase',
      data: {
        'patientId': patientId,
        'branchId': branchId,
        'studyIds': studyIds,
      },
    );
    final j = res.data!;
    // Usamos patientId/branchId del request porque el backend puede
    // omitirlos del response (whitelist de NestJS los descarta del DTO
    // si falta decorador). El QR se construye en el cliente con datos
    // correctos via toQrPayload().
    final parsedStudyIds = (j['studyIds'] as List<dynamic>)
        .map((e) => (e as num).toInt())
        .toList();
    return CheckinPass(
      token: j['token'] as String,
      patientId: (j['patientId'] as String?) ?? patientId,
      branchId: (j['branchId'] as num?)?.toInt() ?? branchId,
      studyIds: parsedStudyIds,
      issuedAt: DateTime.parse(j['issuedAt'] as String),
      expiresAt: DateTime.parse(j['expiresAt'] as String),
    );
  }

  Future<ClinicalValidation> validateClinicalRules({
    required List<int> studyIds,
    required bool hasMedicalOrder,
    DateTime? sampleCollectedAt,
    String? patientId,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/checkin/validacion-clinica',
      data: {
        'studyIds': studyIds,
        'hasMedicalOrder': hasMedicalOrder,
        if (sampleCollectedAt != null)
          'sampleCollectedAt': sampleCollectedAt.toIso8601String(),
        if (patientId != null) 'patientId': patientId,
      },
    );
    final j = res.data!;
    final raw = j['status'] as String;
    final status = switch (raw) {
      'requires_medical_order' =>
        ClinicalValidationStatus.requiresMedicalOrder,
      'sample_expired' => ClinicalValidationStatus.sampleExpired,
      _ => ClinicalValidationStatus.ok,
    };
    return ClinicalValidation(status: status, message: j['message'] as String);
  }
}
