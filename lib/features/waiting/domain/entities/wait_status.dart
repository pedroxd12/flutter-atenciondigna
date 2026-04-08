import 'package:equatable/equatable.dart';

class WaitBranch extends Equatable {
  const WaitBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [id, name, lat, lng];
}

class WaitStatus extends Equatable {
  const WaitStatus({
    required this.currentStudy,
    required this.area,
    required this.peopleAhead,
    required this.estimatedMinutes,
    required this.saturationLevel,
    required this.isYourTurn,
    required this.folio,
    required this.hasActiveService,
    required this.branch,
  });

  final String currentStudy;
  final String area;
  final int peopleAhead;
  final double estimatedMinutes;
  final String saturationLevel;
  final bool isYourTurn;

  /// Folio del check-in. Null si aun no se ha asignado.
  final String? folio;

  /// True si el paciente tiene una cita activa hoy.
  final bool hasActiveService;

  /// Sucursal de la cita activa. Null si no hay cita.
  final WaitBranch? branch;

  @override
  List<Object?> get props => [
        currentStudy,
        peopleAhead,
        estimatedMinutes,
        isYourTurn,
        folio,
        hasActiveService,
        branch,
      ];
}

class QueueItem extends Equatable {
  const QueueItem({
    required this.initials,
    required this.folio,
    required this.estudio,
    required this.posicion,
    required this.isCurrent,
    required this.isMine,
  });

  final String initials;
  final String folio;
  final String estudio;
  final int posicion;
  final bool isCurrent;
  final bool isMine;

  @override
  List<Object?> get props => [folio, posicion, isCurrent, isMine];
}
