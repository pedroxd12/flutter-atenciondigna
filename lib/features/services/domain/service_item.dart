import 'package:equatable/equatable.dart';

class ServiceCategory extends Equatable {
  const ServiceCategory({
    required this.id,
    required this.nombre,
    required this.total,
  });

  final int id;
  final String nombre;
  final int total;

  @override
  List<Object?> get props => [id, nombre, total];
}

class ServiceItem extends Equatable {
  const ServiceItem({
    required this.id,
    required this.idEstudio,
    required this.categoria,
    required this.nombre,
    required this.precio,
    required this.esPaquete,
    required this.requierePreparacion,
    required this.preparacion,
  });

  final int id;
  final int idEstudio;
  final String categoria;
  final String nombre;
  final double? precio;
  final bool esPaquete;
  final bool requierePreparacion;
  final String? preparacion;

  @override
  List<Object?> get props => [
        id,
        idEstudio,
        categoria,
        nombre,
        precio,
        esPaquete,
        requierePreparacion,
        preparacion,
      ];
}
