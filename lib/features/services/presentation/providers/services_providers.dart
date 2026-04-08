import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/services_remote_datasource.dart';
import '../../domain/service_item.dart';

final servicesRemoteProvider = Provider<ServicesRemoteDataSource>(
  (ref) => ServicesRemoteDataSource(ref.watch(apiClientProvider)),
);

final categoriasProvider = FutureProvider<List<ServiceCategory>>(
  (ref) => ref.watch(servicesRemoteProvider).getCategorias(),
);

final serviciosPorCategoriaProvider =
    FutureProvider.family<List<ServiceItem>, int>((ref, idEstudio) {
  return ref.watch(servicesRemoteProvider).getServiciosPorCategoria(idEstudio);
});
