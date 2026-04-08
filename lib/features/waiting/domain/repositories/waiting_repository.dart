import '../entities/wait_status.dart';

abstract class WaitingRepository {
  /// Stream del estado en vivo. En produccion: WebSocket / Server-Sent Events
  /// servido por el backend Nest, que combina cola real + prediccion IA.
  Stream<WaitStatus> watchStatus();
}
