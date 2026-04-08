import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/survey_remote_datasource.dart';
import '../../domain/entities/survey_answer.dart';

final surveyRemoteProvider = Provider<SurveyRemoteDataSource>(
  (ref) => SurveyRemoteDataSource(ref.watch(apiClientProvider)),
);

class SubmitSurveyParams {
  SubmitSurveyParams({required this.branchId, required this.answers});
  final int branchId;
  final List<SurveyAnswer> answers;
}

final submitSurveyProvider = Provider<Future<void> Function(SubmitSurveyParams)>(
  (ref) => (params) async {
    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null) return;
    await ref.watch(surveyRemoteProvider).submit(
          patientId: patientId,
          branchId: params.branchId,
          answers: params.answers,
        );
  },
);
