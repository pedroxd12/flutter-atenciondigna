import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/checkin_remote_datasource.dart';
import '../../domain/entities/checkin_pass.dart';

final checkinRemoteProvider = Provider<CheckinRemoteDataSource>(
  (ref) => CheckinRemoteDataSource(ref.watch(apiClientProvider)),
);

class CheckinPassParams {
  CheckinPassParams({
    required this.patientId,
    required this.branchId,
    required this.studyIds,
  });
  final String patientId;
  final int branchId;
  final List<int> studyIds;

  @override
  bool operator ==(Object other) =>
      other is CheckinPassParams &&
      other.patientId == patientId &&
      other.branchId == branchId &&
      _listEq(other.studyIds, studyIds);

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(patientId, branchId, Object.hashAll(studyIds));
}

final checkinPassProvider =
    FutureProvider.family<CheckinPass, CheckinPassParams>((ref, p) async {
      return ref.watch(checkinRemoteProvider).generatePass(
            patientId: p.patientId,
            branchId: p.branchId,
            studyIds: p.studyIds,
          );
    });

class ClinicalValidationParams {
  ClinicalValidationParams({
    required this.studyIds,
    required this.hasMedicalOrder,
    this.sampleCollectedAt,
  });
  final List<int> studyIds;
  final bool hasMedicalOrder;
  final DateTime? sampleCollectedAt;
}

final clinicalValidationProvider =
    FutureProvider.family<ClinicalValidation, ClinicalValidationParams>(
      (ref, p) async {
        return ref.watch(checkinRemoteProvider).validateClinicalRules(
              studyIds: p.studyIds,
              hasMedicalOrder: p.hasMedicalOrder,
              sampleCollectedAt: p.sampleCollectedAt,
            );
      },
    );
