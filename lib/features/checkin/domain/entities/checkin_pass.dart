import 'package:equatable/equatable.dart';

class CheckinPass extends Equatable {
  const CheckinPass({
    required this.token,
    required this.patientId,
    required this.branchId,
    required this.studyIds,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String token;
  final String patientId;
  final int branchId;
  final List<int> studyIds;
  final DateTime issuedAt;
  final DateTime expiresAt;

  /// Payload codificado para el QR (lo escanea recepcion).
  String toQrPayload() =>
      'AD|$token|$patientId|$branchId|${studyIds.join(",")}';

  @override
  List<Object?> get props => [token, patientId, branchId];
}

enum ClinicalValidationStatus { ok, requiresMedicalOrder, sampleExpired }

class ClinicalValidation extends Equatable {
  const ClinicalValidation({
    required this.status,
    required this.message,
  });

  final ClinicalValidationStatus status;
  final String message;

  bool get isOk => status == ClinicalValidationStatus.ok;

  @override
  List<Object?> get props => [status, message];
}
