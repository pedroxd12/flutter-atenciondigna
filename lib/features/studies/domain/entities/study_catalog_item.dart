import 'package:equatable/equatable.dart';

/// Item ligero del catalogo de estudios — usado en selectores como
/// "Solicitar estudio". Refleja la fila correspondiente de la tabla
/// `estudios` en la base de datos.
class StudyCatalogItem extends Equatable {
  const StudyCatalogItem({
    required this.id,
    required this.nombre,
    required this.requierePreparacion,
    required this.requiereOrdenMedica,
    required this.tiempoEsperaPromedio,
  });

  final int id;
  final String nombre;
  final bool requierePreparacion;
  final bool requiereOrdenMedica;
  final int tiempoEsperaPromedio;

  @override
  List<Object?> get props => [id, nombre];
}
