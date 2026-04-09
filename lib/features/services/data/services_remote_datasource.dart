import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/service_item.dart';
import 'salud_digna_catalog.dart';

class ServicesRemoteDataSource {
  ServicesRemoteDataSource(this._api);
  final ApiClient _api;

  /// Catalogo completo desde el backend (12 categorias + variantes +
  /// tiempos REALES en vivo del modelo IA).
  ///
  /// Mapea la respuesta del endpoint NestJS a las clases ya existentes
  /// `CatalogCategory` / `CatalogItem` para no tocar la UI.
  Future<List<CatalogCategory>> getCatalogoCompleto() async {
    final res =
        await _api.dio.get<List<dynamic>>('/servicios/catalogo-completo');
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_categoryFromJson)
        .toList();
  }

  CatalogCategory _categoryFromJson(Map<String, dynamic> j) {
    final items = ((j['items'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (it) => CatalogItem(
            id: it['id'].toString(),
            idEstudio: (it['idEstudio'] as num).toInt(),
            nombre: (it['nombre'] as String?) ?? '',
            precio: it['precio'] == null ? null : (it['precio'] as num).toDouble(),
          ),
        )
        .toList();
    return CatalogCategory(
      idEstudio: (j['idEstudio'] as num).toInt(),
      nombre: (j['nombre'] as String?) ?? '',
      tiempoServicioMin: (j['tiempoServicioMin'] as num?)?.toInt() ?? 15,
      tiempoEsperaPromedioMin:
          (j['tiempoEsperaPromedioMin'] as num?)?.toInt() ?? 20,
      icono: (j['icono'] as String?) ?? 'medical_services',
      descripcion: (j['descripcion'] as String?) ?? '',
      preparacion: (j['preparacion'] as String?) ?? '',
      tiempoEsperaActualMin: (j['tiempoEsperaActualMin'] as num?)?.toDouble(),
      tiempoTotalActualMin: (j['tiempoTotalActualMin'] as num?)?.toInt(),
      tiempoTotalPromedioMin:
          (j['tiempoTotalPromedioMin'] as num?)?.toInt(),
      saturacionActual: j['saturacionActual'] as String?,
      items: items,
    );
  }

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
