/// Configuracion en tiempo de compilacion. Se inyecta con `--dart-define`.
///
/// Comandos:
///   flutter run                                    # default = produccion
///   flutter run --dart-define=ENV=local            # backend local emulador
///   flutter run --dart-define=ENV=local-device     # backend local dispositivo fisico
///   flutter run --dart-define=API_BASE_URL=...     # URL custom
class AppConfig {
  AppConfig._();

  /// Ambientes predefinidos. `ENV` se inyecta con `--dart-define=ENV=...`.
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');

  /// Si pasas `--dart-define=API_BASE_URL=...` tiene prioridad sobre `ENV`.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// URL base del backend NestJS.
  ///
  /// Resolucion:
  ///   1. Si hay --dart-define=API_BASE_URL → usa eso.
  ///   2. Si hay --dart-define=ENV=local → backend local desde emulador Android.
  ///   3. Si hay --dart-define=ENV=local-device → IP de tu PC en LAN.
  ///   4. Default → produccion en Railway.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    switch (_env) {
      case 'local':
        // Loopback del emulador Android hacia el host.
        return 'http://10.0.2.2:3000';
      case 'local-device':
        // Cambia esto por la IP de tu PC en la red WiFi para probar
        // en un dispositivo fisico (`ipconfig` en Windows, `ifconfig` en mac/linux).
        return 'http://192.168.1.100:3000';
      case 'prod':
      default:
        // URL publica del backend en Railway.
        return 'https://backend-atenciondigna-production.up.railway.app';
    }
  }
}
