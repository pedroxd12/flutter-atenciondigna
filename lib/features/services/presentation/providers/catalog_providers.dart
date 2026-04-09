import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/salud_digna_catalog.dart';
import '../../data/services_remote_datasource.dart';

/// Sucursal MVP fija para el hackathon: Coyoacan (id 46).
/// Espejo de SUCURSAL_MVP_ID en modelo-ia/app/config.py.
class CoyoacanBranch {
  static const int id = 46;
  static const String nombre = 'Coyoacan';
  static const String direccion = 'Av. Universidad 1330, Del Valle, Coyoacan, CDMX';
  static const double lat = 19.3568;
  static const double lon = -99.1716;
  static const int horaApertura = 7; // 7:00
  static const int horaCierre = 20; // 20:00
}

/// Datasource del catalogo (HTTP al backend NestJS).
final servicesRemoteProvider = Provider<ServicesRemoteDataSource>(
  (ref) => ServicesRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Catalogo completo del backend con tiempos REALES del modelo IA.
///
/// IMPORTANTE: este provider NO tiene fallback hardcodeado a proposito.
/// Si la BD esta vacia o el backend no responde, la UI muestra estado
/// de error (con un boton de reintentar) en lugar de simular datos
/// que en realidad no existen. Esto evita que el demo enga#e al jurado
/// mostrando paquetes "fantasma" que despues fallan al agendar.
final remoteCatalogProvider = FutureProvider<List<CatalogCategory>>(
  (ref) async {
    final list =
        await ref.watch(servicesRemoteProvider).getCatalogoCompleto();
    return list;
  },
);

/// Versión sincrona del catalogo — devuelve la lista vigente
/// (backend si ya cargo, vacia mientras carga). Lo usan las
/// pantallas que necesitan render inmediato sin estado de loading.
final localCatalogProvider = Provider<List<CatalogCategory>>(
  (ref) => ref.watch(remoteCatalogProvider).asData?.value ?? const [],
);

final categoryByIdProvider = Provider.family<CatalogCategory?, int>(
  (ref, idEstudio) {
    final list = ref.watch(localCatalogProvider);
    for (final c in list) {
      if (c.idEstudio == idEstudio) return c;
    }
    return null;
  },
);

/// Carrito de servicios seleccionados por el paciente antes de agendar.
/// Cada entrada guarda el `CatalogItem` con su precio.
class ServiceCart {
  const ServiceCart({this.items = const []});
  final List<CatalogItem> items;

  bool contains(String id) => items.any((i) => i.id == id);

  ServiceCart toggle(CatalogItem item) {
    if (contains(item.id)) {
      return ServiceCart(items: items.where((i) => i.id != item.id).toList());
    }
    return ServiceCart(items: [...items, item]);
  }

  ServiceCart clear() => const ServiceCart();

  /// Lista unica de id_estudio (para el scheduler global).
  List<int> get idsEstudio {
    final s = <int>{for (final i in items) i.idEstudio};
    return s.toList();
  }

  double get total {
    double t = 0;
    for (final i in items) {
      t += i.precio ?? 0;
    }
    return t;
  }

  int get totalItems => items.length;
}

class ServiceCartNotifier extends StateNotifier<ServiceCart> {
  ServiceCartNotifier() : super(const ServiceCart());

  void toggle(CatalogItem item) => state = state.toggle(item);
  void clear() => state = state.clear();
}

final serviceCartProvider =
    StateNotifierProvider<ServiceCartNotifier, ServiceCart>(
  (ref) => ServiceCartNotifier(),
);
