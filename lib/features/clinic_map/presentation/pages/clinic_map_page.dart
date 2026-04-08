import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/google_static_map.dart';
import '../../../branches/domain/entities/branch.dart';
import '../../../branches/presentation/providers/branches_providers.dart';
import '../../../waiting/presentation/providers/waiting_providers.dart';

/// Mapa para llegar a la sucursal del paciente. Toma la sucursal de la
/// reservacion activa (BD), muestra un mapa real de Google y, si existe
/// `mapa_geojson` en la BD, dibuja las areas internas; si no, muestra un
/// estado vacio (sin layouts inventados).
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
        error: (e, _) => _ErrorState(
          message: 'No pudimos obtener tu cita activa',
          onRetry: () => ref.invalidate(waitStatusProvider),
        ),
        data: (status) {
          if (status == null || !status.hasActiveService || status.branch == null) {
            return const _NoActiveBranchState();
          }
          final waitBranch = status.branch!;
          // Carga el detalle completo (incluye mapa_geojson si existe en BD)
          final detailAsync = ref.watch(branchByIdProvider(waitBranch.id));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (status.area.isNotEmpty)
                Container(
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
                      const Icon(
                        Icons.directions_walk,
                        color: AppColors.primary,
                      ),
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
                              status.area,
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
              const SizedBox(height: 16),
              GoogleStaticMap(
                lat: waitBranch.lat,
                lng: waitBranch.lng,
                zoom: 16,
                height: 240,
                highlight: (lat: waitBranch.lat, lng: waitBranch.lng),
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
                              waitBranch.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              waitBranch.address.isEmpty
                                  ? 'Sin direccion registrada en BD'
                                  : waitBranch.address,
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
        },
      ),
    );
  }
}

/// Renderiza el mapa interno si la sucursal lo tiene capturado en BD.
/// El campo `mapa_geojson` debe contener un objeto con `areas: [{label, x, y, w, h}]`.
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
            color: isDest ? AppColors.saturationCritical : AppColors.textPrimary,
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
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActiveBranchState extends StatelessWidget {
  const _NoActiveBranchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 56, color: AppColors.textSecondary),
            SizedBox(height: 14),
            Text(
              'No hay sucursal activa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Cuando tengas una cita activa veras aqui como llegar a tu sucursal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
