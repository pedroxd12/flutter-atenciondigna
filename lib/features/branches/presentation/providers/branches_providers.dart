import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../location/providers/location_providers.dart';
import '../../data/datasources/branches_remote_datasource.dart';
import '../../data/repositories/branches_remote_repository_impl.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branches_repository.dart';

final branchesRepositoryProvider = Provider<BranchesRepository>((ref) {
  final position = ref.watch(currentPositionProvider);
  final remote = BranchesRemoteDataSource(ref.watch(apiClientProvider));
  return BranchesRemoteRepositoryImpl(
    remote,
    lat: position.lat,
    lng: position.lng,
  );
});

/// Lista de las N sucursales mas cercanas con su tiempo de espera estimado.
final nearestBranchesProvider = FutureProvider.family<List<Branch>, int>(
  (ref, idEstudio) async {
    final repo = ref.watch(branchesRepositoryProvider);
    return repo.getNearestWithWaitTime(idEstudio: idEstudio, limit: 5);
  },
);
