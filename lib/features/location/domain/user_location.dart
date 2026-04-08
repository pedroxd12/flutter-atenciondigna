import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  const UserLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}
