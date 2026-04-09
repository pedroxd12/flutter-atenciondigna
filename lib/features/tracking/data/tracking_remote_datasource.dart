import '../../../core/network/api_client.dart';
import '../domain/entities/tracking_status.dart';

/// Datasource remoto para el tracking del paciente.
/// Consume `GET /tracking/{patientId}` del backend NestJS.
class TrackingRemoteDataSource {
  TrackingRemoteDataSource(this._api);
  final ApiClient _api;

  Future<TrackingStatus> getTracking(String patientId) async {
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/tracking/$patientId',
    );
    return TrackingStatus.fromJson(res.data!);
  }
}
