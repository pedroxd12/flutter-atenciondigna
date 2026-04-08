import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.waitTimeMinutes,
    required this.saturationLevel,
    required this.lat,
    required this.lng,
    this.mapaGeojson,
  });

  final int id;
  final String name;
  final String address;
  final double distanceKm;
  final double waitTimeMinutes;
  final String saturationLevel; // bajo | medio | alto | critico
  final double lat;
  final double lng;

  /// Mapa interno de la clinica (GeoJSON). Null si no fue capturado en BD.
  final Map<String, dynamic>? mapaGeojson;

  @override
  List<Object?> get props => [id, name, distanceKm, waitTimeMinutes];
}
