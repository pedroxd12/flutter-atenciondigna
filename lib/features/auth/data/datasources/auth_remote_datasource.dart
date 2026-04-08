import '../../../../core/network/api_client.dart';

/// Cliente HTTP de los endpoints `/auth/*` del backend NestJS.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: body,
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> google({
    required String firebaseUid,
    required String email,
    required String fullName,
    String? photoUrl,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {
        'firebaseUid': firebaseUid,
        'email': email,
        'fullName': fullName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );
    return res.data!;
  }
}
