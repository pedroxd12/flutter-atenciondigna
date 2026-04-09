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

  /// Horario semanal real (espejo de la columna `horario_semanal` en BD).
  /// Index: 0=Lunes ... 6=Domingo. open/close en horas 0-23.
  ///   - L-V: 6-19
  ///   - Sabado: 6-17
  ///   - Domingo: 6-14
  static const List<({int open, int close})> horarioSemanal = [
    (open: 6, close: 19), // Lunes
    (open: 6, close: 19), // Martes
    (open: 6, close: 19), // Miercoles
    (open: 6, close: 19), // Jueves
    (open: 6, close: 19), // Viernes
    (open: 6, close: 17), // Sabado
    (open: 6, close: 14), // Domingo
  ];

  /// Horario aplicable para una fecha concreta. Devuelve null si la
  /// sucursal no abre ese dia.
  static ({int open, int close})? horarioPara(DateTime fecha) {
    final dow = (fecha.weekday + 6) % 7; // weekday: 1=Lun..7=Dom -> 0=Lun..6=Dom
    if (dow < 0 || dow >= horarioSemanal.length) return null;
    final h = horarioSemanal[dow];
    if (h.open >= h.close) return null;
    return h;
  }

  /// Devuelve la primer fecha (>= hoy) en la que la sucursal todavia
  /// puede recibir pacientes con suficiente margen. Hoy solo cuenta si
  /// faltan al menos 2 horas para el cierre Y la apertura ya paso (o
  /// pasara dentro de la misma hora). Sino, salta al siguiente dia.
  static DateTime nextAvailableDate() {
    final ahora = DateTime.now();
    for (var i = 0; i < 14; i++) {
      final d = DateTime(ahora.year, ahora.month, ahora.day).add(
        Duration(days: i),
      );
      final h = horarioPara(d);
      if (h == null) continue;
      if (i == 0) {
        // Hoy: necesitamos al menos 2h antes del cierre para tener slots
        // utiles, contando que el modelo IA reserva 1h de margen propio.
        final horaInicio = ahora.hour < h.open ? h.open : ahora.hour + 1;
        if (horaInicio + 1 < h.close) return d;
      } else {
        return d;
      }
    }
    return DateTime(ahora.year, ahora.month, ahora.day).add(
      const Duration(days: 1),
    );
  }

  /// Encuentra la siguiente fecha valida ESTRICTAMENTE despues de `from`.
  /// Util cuando el backend nos dice que `from` no tiene horarios:
  /// avanzamos al siguiente dia abierto (con horario, no necesariamente
  /// hoy + 1).
  static DateTime nextAvailableAfter(DateTime from) {
    final base = DateTime(from.year, from.month, from.day);
    for (var i = 1; i < 14; i++) {
      final d = base.add(Duration(days: i));
      if (horarioPara(d) != null) return d;
    }
    return base.add(const Duration(days: 1));
  }

  /// Compatibilidad legacy.
  static int get horaApertura => horarioSemanal[0].open;
  static int get horaCierre => horarioSemanal[0].close;
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
