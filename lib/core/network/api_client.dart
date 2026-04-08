import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Cliente HTTP centralizado. Apunta al backend NestJS, que a su vez
/// reenvia al microservicio IA cuando aplica.
///
/// Los providers de Riverpod inyectan una unica instancia de esta clase
/// y los repositorios la consumen. El token JWT se setea via `setAuthToken`
/// despues del login y queda en `Authorization: Bearer ...` para todas las
/// peticiones siguientes.
class ApiClient {
  ApiClient({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // Aceptamos 4xx para que el repo decida que hacer (mejor mensajes
          // de error tipo "credenciales invalidas" en lugar de "exception").
          validateStatus: (status) => status != null && status < 500,
        ),
      ) {
    // Solo en debug imprimimos las peticiones — en release queda silencioso.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  /// La URL base activa (util para mostrar en pantallas de debug).
  String get baseUrl => _dio.options.baseUrl;

  void setAuthToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
