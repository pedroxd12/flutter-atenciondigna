import 'package:equatable/equatable.dart';

class Patient extends Equatable {
  const Patient({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;

  String get firstName => fullName.split(' ').first;

  @override
  List<Object?> get props => [id, email, fullName, photoUrl];
}
