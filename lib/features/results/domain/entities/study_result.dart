import 'package:equatable/equatable.dart';

class StudyResult extends Equatable {
  const StudyResult({
    required this.id,
    required this.studyName,
    required this.branchName,
    required this.takenAt,
    required this.readyAt,
    required this.status,
  });

  final String id;
  final String studyName;
  final String branchName;
  final DateTime takenAt;
  final DateTime readyAt;
  final ResultStatus status;

  bool get isReady => status == ResultStatus.ready;

  @override
  List<Object?> get props => [id, status];
}

enum ResultStatus { processing, ready }
