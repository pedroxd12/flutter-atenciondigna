import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../location/providers/location_providers.dart';
import '../../data/datasources/branches_remote_datasource.dart';
import '../../domain/entities/branch.dart';

/// Excepcion sentinel para que la UI muestre el estado vacio
/// "necesitamos tu ubicacion" en lugar de un error generico.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException();
  @override
  String toString() => 'LocationUnavailableException';
}

final branchesRemoteProvider = Provider<BranchesRemoteDataSource>(
  (ref) => BranchesRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Detalle de una sucursal por id (incluye `mapaGeojson` si la BD lo tiene).
final branchByIdProvider = FutureProvider.family<Branch, int>(
  (ref, id) => ref.watch(branchesRemoteProvider).getById(id),
);

/// Lista de las N sucursales mas cercanas con su tiempo de espera estimado.
/// Si el usuario no compartio su ubicacion, lanza
/// [LocationUnavailableException] para que la UI muestre un estado vacio.
final nearestBranchesProvider = FutureProvider.family<List<Branch>, int>(
  (ref, idEstudio) async {
    final position = ref.watch(currentPositionProvider);
    if (position == null) {
      throw const LocationUnavailableException();
    }
    return ref.watch(branchesRemoteProvider).nearestWithWait(
          lat: position.lat,
          lng: position.lng,
          idEstudio: idEstudio,
          limit: 5,
        );
  },
);
