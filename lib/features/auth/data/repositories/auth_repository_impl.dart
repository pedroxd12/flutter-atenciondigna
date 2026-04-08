import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementacion real contra el backend NestJS.
///
/// - email/password: POST /auth/register, POST /auth/login
/// - google: requiere `flutterfire configure` (lanza UnimplementedError mientras tanto)
///
/// Guarda el token JWT en SharedPreferences y lo inyecta en cada request
/// del ApiClient via setAuthToken.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required AuthRemoteDataSource remote,
    required TokenStorage storage,
  })  : _api = apiClient,
        _remote = remote,
        _storage = storage;

  final ApiClient _api;
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  @override
  Future<Patient> register({
    required String email,
    required String password,
    required String nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
  }) async {
    try {
      final res = await _remote.register({
        'email': email,
        'password': password,
        'nombre': nombre,
        if (apellidoPaterno != null) 'apellidoPaterno': apellidoPaterno,
        if (apellidoMaterno != null) 'apellidoMaterno': apellidoMaterno,
        if (telefono != null) 'telefono': telefono,
      });
      return _persist(res);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  @override
  Future<Patient> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _remote.login(email: email, password: password);
      return _persist(res);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  @override
  Future<Patient> signInWithGoogle() async {
    throw UnimplementedError(
      'Google Sign-In requiere `flutterfire configure`. '
      'Mientras tanto, usa correo y contrasena.',
    );
  }

  @override
  Future<void> signOut() async {
    await _storage.clear();
    _api.setAuthToken(null);
  }

  @override
  Future<Patient?> currentUser() async {
    final token = await _storage.token();
    if (token == null) return null;
    _api.setAuthToken(token);
    final p = await _storage.patient();
    if (p == null) return null;
    return Patient(id: p.id, email: p.email, fullName: p.fullName);
  }

  // ────────────────────────────────────────────────
  Future<Patient> _persist(Map<String, dynamic> json) async {
    final token = json['token'] as String;
    final p = json['patient'] as Map<String, dynamic>;
    final patient = Patient(
      id: p['id'] as String,
      email: p['email'] as String,
      fullName: p['fullName'] as String,
      photoUrl: p['photoUrl'] as String?,
    );
    await _storage.save(
      token: token,
      patientId: patient.id,
      email: patient.email,
      fullName: patient.fullName,
    );
    _api.setAuthToken(token);
    return patient;
  }

  Exception _toReadable(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      return Exception(msg is List ? msg.join(', ') : msg.toString());
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception(
        'No pudimos conectar con el servidor. Revisa tu conexion.',
      );
    }
    return Exception('Ocurrio un error. Intenta de nuevo.');
  }
}
