import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/study.dart';
import '../../domain/entities/study_catalog_item.dart';

class StudiesRemoteDataSource {
  StudiesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<StudyCatalogItem>> getCatalogo() async {
    final res = await _api.dio.get<List<dynamic>>('/estudios');
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (j) => StudyCatalogItem(
            id: (j['id'] as num).toInt(),
            nombre: j['nombre'] as String,
            requierePreparacion: j['requierePreparacion'] as bool,
            requiereOrdenMedica: j['requiereOrdenMedica'] as bool,
            tiempoEsperaPromedio:
                (j['tiempoEsperaPromedio'] as num?)?.toInt() ?? 20,
          ),
        )
        .toList();
  }

  Future<List<Study>> getTodaysStudies(String patientId) async {
    try {
      final res = await _api.dio.get<List<dynamic>>(
        '/pacientes/$patientId/estudios-hoy',
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();
    } on DioException catch (e) {
      // 404 significa que no hay reservacion activa hoy, lo cual es un estado
      // valido (el usuario no tiene cita). Devolvemos lista vacia.
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  Study _fromJson(Map<String, dynamic> j) => Study(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    estimatedMinutes: (j['estimatedMinutes'] as num).toDouble(),
    requiresPreparation: j['requiresPreparation'] as bool,
    preparations: (j['preparations'] as List<dynamic>).cast<String>(),
    requiresMedicalOrder: j['requiresMedicalOrder'] as bool,
    area: j['area'] as String,
  );
}
