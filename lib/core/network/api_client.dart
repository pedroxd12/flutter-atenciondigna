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
          // Solo 2xx/3xx se consideran exito. 4xx y 5xx lanzan DioException
          // y los repos los traducen a mensajes legibles via _toReadable.
          validateStatus: (status) => status != null && status < 400,
        ),
      ) {
    // Log de la URL base al iniciar — util para confirmar contra que backend
    // estamos pegando (Railway, local, etc.).
    debugPrint('[ApiClient] baseUrl = ${_dio.options.baseUrl}');

    // Solo en debug imprimimos las peticiones — en release queda silencioso.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
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
