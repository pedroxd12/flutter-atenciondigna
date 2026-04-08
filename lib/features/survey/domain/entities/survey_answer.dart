import 'package:equatable/equatable.dart';

class SurveyAnswer extends Equatable {
  const SurveyAnswer({
    required this.questionId,
    required this.rating,
  });

  final String questionId;
  final int rating; // 1..5

  @override
  List<Object?> get props => [questionId, rating];
}
