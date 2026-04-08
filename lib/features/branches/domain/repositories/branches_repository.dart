import '../entities/branch.dart';

abstract class BranchesRepository {
  /// Devuelve las N sucursales mas cercanas con su tiempo de espera estimado
  /// (calculado por el microservicio IA via /ia/sucursal/{id}/saturacion).
  Future<List<Branch>> getNearestWithWaitTime({
    required int idEstudio,
    int limit = 3,
  });
}
