import 'package:equatable/equatable.dart';

class WaitStatus extends Equatable {
  const WaitStatus({
    required this.currentStudy,
    required this.area,
    required this.peopleAhead,
    required this.estimatedMinutes,
    required this.saturationLevel,
    required this.isYourTurn,
  });

  final String currentStudy;
  final String area;
  final int peopleAhead;
  final double estimatedMinutes;
  final String saturationLevel;
  final bool isYourTurn;

  WaitStatus copyWith({
    int? peopleAhead,
    double? estimatedMinutes,
    bool? isYourTurn,
  }) {
    return WaitStatus(
      currentStudy: currentStudy,
      area: area,
      peopleAhead: peopleAhead ?? this.peopleAhead,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      saturationLevel: saturationLevel,
      isYourTurn: isYourTurn ?? this.isYourTurn,
    );
  }

  @override
  List<Object?> get props => [
    currentStudy,
    peopleAhead,
    estimatedMinutes,
    isYourTurn,
  ];
}
