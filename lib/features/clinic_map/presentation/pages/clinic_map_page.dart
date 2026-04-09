import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/google_static_map.dart';
import '../../../branches/domain/entities/branch.dart';
import '../../../branches/presentation/providers/branches_providers.dart';
import '../../../services/presentation/providers/catalog_providers.dart';
import '../../../waiting/presentation/providers/waiting_providers.dart';

/// Branch fallback (Coyoacan) — para cuando el paciente abre el mapa
/// sin tener una cita activa. Asi el mapa SIEMPRE carga.
const Branch _kCoyoacanFallback = Branch(
  id: CoyoacanBranch.id,
  name: 'Salud Digna Coyoacan',
  address: CoyoacanBranch.direccion,
  distanceKm: 0,
  waitTimeMinutes: 20,
  saturationLevel: 'medio',
  lat: CoyoacanBranch.lat,
  lng: CoyoacanBranch.lon,
);

/// Mapa para llegar a la sucursal del paciente. Toma la sucursal de la
/// reservacion activa (BD), muestra un mapa real de Google y, si existe
/// `mapa_geojson` en la BD, dibuja las areas internas. Si no hay cita
/// activa o falla la consulta, cae a Coyoacan (sucursal MVP) para que
/// el usuario nunca vea una pantalla vacia.
class ClinicMapPage extends ConsumerWidget {
  const ClinicMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(waitStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Como llegar'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Content(
          branch: _kCoyoacanFallback,
          destinationLabel: '',
          isFallback: true,
        ),
        data: (status) {
          final hasActive = status?.hasActiveService == true &&
              status?.branch != null;
          final Branch branch;
          if (hasActive) {
            final wb = status!.branch!;
            branch = Branch(
              id: wb.id,
              name: wb.name,
              address: wb.address,
              distanceKm: 0,
              waitTimeMinutes: status.estimatedMinutes,
              saturationLevel: status.saturationLevel,
              lat: wb.lat,
              lng: wb.lng,
            );
          } else {
            branch = _kCoyoacanFallback;
          }
          return _Content(
            branch: branch,
            destinationLabel: status?.area ?? '',
            isFallback: !hasActive,
          );
        },
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.branch,
    required this.destinationLabel,
    required this.isFallback,
  });

  final Branch branch;
  final String destinationLabel;
  final bool isFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(branchByIdProvider(branch.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (isFallback)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No tienes una cita activa. Te mostramos la sucursal MVP de Coyoacan.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        if (destinationLabel.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_walk, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu destino',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        destinationLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        GoogleStaticMap(
          lat: branch.lat,
          lng: branch.lng,
          zoom: 16,
          height: 240,
          highlight: (lat: branch.lat, lng: branch.lng),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branch.address.isEmpty
                            ? 'Sin direccion registrada en BD'
                            : branch.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'MAPA INTERNO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        detailAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _NoIndoorMap(),
          data: (b) => _IndoorMapView(branch: b),
        ),
      ],
    );
  }
}

class _IndoorMapView extends StatelessWidget {
  const _IndoorMapView({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final geo = branch.mapaGeojson;
    if (geo == null) return const _NoIndoorMap();

    final areas = (geo['areas'] as List?) ?? const [];
    if (areas.isEmpty) return const _NoIndoorMap();

    return Card(
      child: SizedBox(
        height: 280,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _IndoorPainter(
              areas: areas
                  .cast<Map>()
                  .map((m) => m.cast<String, dynamic>())
                  .toList(),
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _IndoorPainter extends CustomPainter {
  _IndoorPainter({required this.areas});
  final List<Map<String, dynamic>> areas;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Offset.zero & size, bg);

    for (final a in areas) {
      final rect = Rect.fromLTWH(
        (a['x'] as num).toDouble(),
        (a['y'] as num).toDouble(),
        (a['w'] as num).toDouble(),
        (a['h'] as num).toDouble(),
      );
      final isDest = (a['isDestination'] as bool?) ?? false;
      final fill = Paint()
        ..color = isDest
            ? AppColors.saturationCritical.withValues(alpha: 0.18)
            : Colors.white;
      final stroke = Paint()
        ..color = isDest ? AppColors.saturationCritical : AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = isDest ? 2.5 : 1;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);

      final tp = TextPainter(
        text: TextSpan(
          text: a['label'] as String? ?? '',
          style: TextStyle(
            color: isDest
                ? AppColors.saturationCritical
                : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isDest ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(maxWidth: rect.width - 8);
      tp.paint(
        canvas,
        Offset(
          rect.center.dx - tp.width / 2,
          rect.center.dy - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NoIndoorMap extends StatelessWidget {
  const _NoIndoorMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.layers_clear, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta sucursal aun no tiene mapa interno registrado en la base de datos.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
