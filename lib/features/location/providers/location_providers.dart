import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_service.dart';
import '../domain/user_location.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Ubicacion en cache. `null` cuando no hay permisos o GPS — en ese caso
/// la app muestra un estado vacio en lugar de inventar coordenadas.
final currentPositionProvider = StateProvider<UserLocation?>((ref) => null);

/// Disparalo desde `ref.read(refreshLocationProvider.future)` para forzar
/// la actualizacion (p.ej. al abrir la pantalla de sucursales).
final refreshLocationProvider = FutureProvider<UserLocation?>((ref) async {
  final loc = await ref.read(locationServiceProvider).getCurrentLocation();
  ref.read(currentPositionProvider.notifier).state = loc;
  return loc;
});
