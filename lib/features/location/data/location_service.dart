import 'package:geolocator/geolocator.dart';

import '../domain/user_location.dart';

/// Wrapper sobre `geolocator` con manejo de permisos y fallback.
///
/// Si el usuario niega permisos o el dispositivo no tiene GPS, devolvemos
/// `UserLocation.fallback` (Coyoacan) para que el flujo no se rompa.
class LocationService {
  Future<UserLocation> getCurrentLocation() async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) return UserLocation.fallback;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return UserLocation.fallback;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return UserLocation(lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return UserLocation.fallback;
    }
  }
}
