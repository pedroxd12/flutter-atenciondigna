import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../location/providers/location_providers.dart';
import '../../../services/presentation/providers/catalog_providers.dart';
import '../../data/datasources/branches_remote_datasource.dart';
import '../../domain/entities/branch.dart';

/// Excepcion sentinel — se mantiene para retrocompatibilidad pero ya no se
/// usa: cuando no hay ubicacion del usuario, caemos al fallback de Coyoacan
/// (sucursal MVP) y el mapa carga normalmente.
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

/// Sucursal MVP unica (Coyoacan, id 46) — espejo del backend Python.
/// Para el hackathon SIEMPRE devolvemos esta sucursal y nada mas, sin
/// importar lo que diga el backend (que aun trae datos seed de prueba).
final _coyoacanBranch = Branch(
  id: CoyoacanBranch.id,
  name: 'Salud Digna Coyoacan',
  address: CoyoacanBranch.direccion,
  distanceKm: 0,
  waitTimeMinutes: 20,
  saturationLevel: 'medio',
  lat: CoyoacanBranch.lat,
  lng: CoyoacanBranch.lon,
);

/// Lista de sucursales sugeridas — para el MVP devolvemos UNICAMENTE
/// Coyoacan. Cuando se quiera reactivar el ranking real, basta con
/// volver a llamar a `nearestWithWait` aqui.
final nearestBranchesProvider = FutureProvider.family<List<Branch>, int>(
  (ref, idEstudio) async {
    // Toca la posicion para que la pagina re-renderice cuando cambia,
    // pero no la usamos para filtrar.
    ref.watch(currentPositionProvider);
    return [_coyoacanBranch];
  },
);
