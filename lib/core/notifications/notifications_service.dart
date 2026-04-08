import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manejo de notificaciones push.
///
/// REQUIERE:
///   - `flutterfire configure` (mismo setup que Firebase Auth)
///   - Permisos de notificacion (Android 13+ / iOS): se piden al primer init
///   - Para iOS: APNs key configurada en Firebase Console
///
/// Tipos de notificacion que esta app dispara desde el backend:
///   - `preparation_reminder` — recordatorio de ayuno/preparacion
///   - `your_turn` — el paciente debe pasar al area
///   - `result_ready` — un resultado de estudio ya esta disponible
class NotificationsService {
  NotificationsService._();
  static final instance = NotificationsService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'atencion_digna_default',
    'Atencion Digna',
    description: 'Notificaciones de turno, preparaciones y resultados',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;

    // 1. Permisos del sistema
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Plugin local (foreground display)
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // 3. Display de mensajes foreground (FCM no los muestra solo)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _initialized = true;
  }

  void _handleForegroundMessage(RemoteMessage msg) {
    final n = msg.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: msg.data.toString(),
    );
  }

  /// Token FCM del dispositivo. El backend lo asocia al `patientId` para
  /// poder enviar notificaciones dirigidas (turno, resultados, etc.).
  Future<String?> getDeviceToken() => FirebaseMessaging.instance.getToken();
}
