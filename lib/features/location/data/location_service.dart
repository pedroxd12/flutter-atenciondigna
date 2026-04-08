import 'package:geolocator/geolocator.dart';

import '../domain/user_location.dart';

/// Wrapper sobre `geolocator` con manejo de permisos.
///
/// Devuelve `null` cuando no hay permisos / GPS / posicion disponible —
/// la app debe mostrar un estado vacio en lugar de inventar coordenadas.
class LocationService {
  Future<UserLocation?> getCurrentLocation() async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return UserLocation(lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
