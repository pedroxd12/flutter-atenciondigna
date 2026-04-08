import '../entities/patient.dart';

abstract class AuthRepository {
  Future<Patient> register({
    required String email,
    required String password,
    required String nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
  });

  Future<Patient> login({
    required String email,
    required String password,
  });

  /// Disponible solo si Firebase esta configurado en el proyecto.
  Future<Patient> signInWithGoogle();

  Future<void> signOut();

  /// Recupera el paciente desde almacenamiento local (auto-login al abrir).
  Future<Patient?> currentUser();
}
