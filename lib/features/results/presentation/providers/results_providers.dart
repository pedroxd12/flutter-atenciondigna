import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/results_remote_datasource.dart';
import '../../domain/entities/study_result.dart';

final resultsRemoteProvider = Provider<ResultsRemoteDataSource>(
  (ref) => ResultsRemoteDataSource(ref.watch(apiClientProvider)),
);

final myResultsProvider = FutureProvider<List<StudyResult>>((ref) async {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null) return const [];
  return ref.watch(resultsRemoteProvider).getMyResults(patientId);
});
