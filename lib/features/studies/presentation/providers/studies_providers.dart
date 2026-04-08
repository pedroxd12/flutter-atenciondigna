import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/studies_remote_datasource.dart';
import '../../domain/entities/study.dart';
import '../../domain/entities/study_catalog_item.dart';

final studiesRemoteProvider = Provider<StudiesRemoteDataSource>(
  (ref) => StudiesRemoteDataSource(ref.watch(apiClientProvider)),
);

final todaysStudiesProvider = FutureProvider<List<Study>>((ref) async {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null) return const [];
  return ref.watch(studiesRemoteProvider).getTodaysStudies(patientId);
});

/// Catalogo completo de estudios disponibles — viene de la BD via /estudios.
/// Reemplaza listas hardcodeadas en la UI (ej: request_service_page).
final studiesCatalogProvider = FutureProvider<List<StudyCatalogItem>>(
  (ref) => ref.watch(studiesRemoteProvider).getCatalogo(),
);
