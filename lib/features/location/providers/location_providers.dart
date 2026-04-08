import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_service.dart';
import '../domain/user_location.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Ubicacion en cache. Empieza en `fallback` y se actualiza cuando
/// `refreshLocationProvider` resuelve.
final currentPositionProvider = StateProvider<UserLocation>(
  (ref) => UserLocation.fallback,
);

/// Disparalo desde `ref.read(refreshLocationProvider.future)` para forzar
/// la actualizacion (p.ej. al abrir la pantalla de sucursales).
final refreshLocationProvider = FutureProvider<UserLocation>((ref) async {
  final loc = await ref.read(locationServiceProvider).getCurrentLocation();
  ref.read(currentPositionProvider.notifier).state = loc;
  return loc;
});
