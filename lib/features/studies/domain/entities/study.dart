import 'package:equatable/equatable.dart';

class Study extends Equatable {
  const Study({
    required this.id,
    required this.name,
    required this.estimatedMinutes,
    required this.requiresPreparation,
    required this.preparations,
    required this.requiresMedicalOrder,
    required this.area,
  });

  final int id;
  final String name;
  final double estimatedMinutes;
  final bool requiresPreparation;
  final List<String> preparations;
  final bool requiresMedicalOrder;
  final String area; // ej: "Laboratorio", "Imagenologia"

  @override
  List<Object?> get props => [id, name];
}
