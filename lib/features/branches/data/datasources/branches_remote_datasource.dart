import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/branch.dart';

class BranchesRemoteDataSource {
  BranchesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Branch>> nearestWithWait({
    required double lat,
    required double lng,
    required int idEstudio,
    int limit = 3,
  }) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/sucursales/cercanas',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'id_estudio': idEstudio,
        'limit': limit,
      },
      options: Options(responseType: ResponseType.json),
    );

    final data = res.data ?? const [];
    return data.cast<Map<String, dynamic>>().map(_fromJson).toList();
  }

  Branch _fromJson(Map<String, dynamic> j) => Branch(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    address: j['address'] as String,
    distanceKm: (j['distanceKm'] as num).toDouble(),
    waitTimeMinutes: (j['waitTimeMinutes'] as num).toDouble(),
    saturationLevel: j['saturationLevel'] as String,
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
  );
}
