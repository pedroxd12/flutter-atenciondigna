import '../../domain/entities/branch.dart';
import '../../domain/repositories/branches_repository.dart';
import '../datasources/branches_remote_datasource.dart';

class BranchesRemoteRepositoryImpl implements BranchesRepository {
  BranchesRemoteRepositoryImpl(
    this._remote, {
    required this.lat,
    required this.lng,
  });

  final BranchesRemoteDataSource _remote;
  final double lat;
  final double lng;

  @override
  Future<List<Branch>> getNearestWithWaitTime({
    required int idEstudio,
    int limit = 3,
  }) {
    return _remote.nearestWithWait(
      lat: lat,
      lng: lng,
      idEstudio: idEstudio,
      limit: limit,
    );
  }
}
