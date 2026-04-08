import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  const UserLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;

  /// Coordenadas por defecto: Coyoacan, CDMX. Se usa cuando el usuario
  /// niega permisos de ubicacion o cuando geolocator no esta disponible
  /// (ej: pruebas en escritorio).
  static const fallback = UserLocation(lat: 19.3417, lng: -99.1612);

  @override
  List<Object?> get props => [lat, lng];
}
