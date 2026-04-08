import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.branchId,
    required this.date,
    required this.time,
    required this.studyIds,
    required this.status,
  });
  final String id;
  final int branchId;
  final String date;
  final String? time;
  final List<int> studyIds;
  final String status;

  @override
  List<Object?> get props => [id, branchId, date, time];
}
