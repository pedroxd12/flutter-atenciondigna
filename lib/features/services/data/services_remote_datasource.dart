import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/service_item.dart';

class ServicesRemoteDataSource {
  ServicesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<ServiceCategory>> getCategorias() async {
    try {
      final res = await _api.dio.get<List<dynamic>>('/servicios/categorias');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (j) => ServiceCategory(
              id: (j['id'] as num).toInt(),
              nombre: j['nombre'] as String,
              total: (j['total'] as num).toInt(),
            ),
          )
          .toList();
    } on DioException catch (e) {
      // Si el endpoint no existe (404) o no hay datos, devolvemos lista vacia
      // para evitar que la UI se rompa.
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<List<ServiceItem>> getServiciosPorCategoria(int idEstudio) async {
    final res =
        await _api.dio.get<List<dynamic>>('/servicios/categoria/$idEstudio');
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  ServiceItem _fromJson(Map<String, dynamic> j) => ServiceItem(
        id: (j['id'] as num).toInt(),
        idEstudio: (j['idEstudio'] as num).toInt(),
        categoria: j['categoria'] as String,
        nombre: j['nombre'] as String,
        precio: j['precio'] == null ? null : (j['precio'] as num).toDouble(),
        esPaquete: j['esPaquete'] as bool,
        requierePreparacion: j['requierePreparacion'] as bool,
        preparacion: j['preparacion'] as String?,
      );
}
