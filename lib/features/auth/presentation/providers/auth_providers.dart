import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(
    apiClient: api,
    remote: AuthRemoteDataSource(api),
    storage: ref.watch(tokenStorageProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<Patient?>> {
  AuthController(this._repo) : super(const AsyncValue.data(null)) {
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    try {
      final p = await _repo.currentUser();
      state = AsyncValue.data(p);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final patient = await _repo.login(email: email, password: password);
      state = AsyncValue.data(patient);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? telefono,
  }) async {
    state = const AsyncValue.loading();
    try {
      final patient = await _repo.register(
        email: email,
        password: password,
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        telefono: telefono,
      );
      state = AsyncValue.data(patient);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final patient = await _repo.signInWithGoogle();
      state = AsyncValue.data(patient);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<Patient?>>(
      (ref) => AuthController(ref.watch(authRepositoryProvider)),
    );

/// Helper centralizado: ID del paciente actual o null si no hay sesion.
final currentPatientIdProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).valueOrNull?.id,
);
