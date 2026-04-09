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

/// Areas internas predefinidas de la sucursal para el plano simplificado.
/// Cada area tiene un id, nombre, icono, y una pista de ubicacion.
class _ClinicArea {
  const _ClinicArea({
    required this.id,
    required this.name,
    required this.icon,
    required this.locationHint,
    required this.waitMinutes,
  });
  final String id;
  final String name;
  final IconData icon;
  final String locationHint;
  final int waitMinutes;
}

const _kDefaultAreas = <_ClinicArea>[
  _ClinicArea(
    id: 'recepcion',
    name: 'Recepcion',
    icon: Icons.badge_outlined,
    locationHint: 'Entrada principal — Planta baja',
    waitMinutes: 5,
  ),
  _ClinicArea(
    id: 'laboratorio',
    name: 'Laboratorio',
    icon: Icons.science_outlined,
    locationHint: 'Planta baja, ala derecha',
    waitMinutes: 15,
  ),
  _ClinicArea(
    id: 'rayos_x',
    name: 'Rayos X',
    icon: Icons.center_focus_strong_outlined,
    locationHint: 'Planta baja, seccion de imagenologia',
    waitMinutes: 20,
  ),
  _ClinicArea(
    id: 'ultrasonido',
    name: 'Ultrasonido',
    icon: Icons.monitor_heart_outlined,
    locationHint: 'Primer piso, consultorio 3',
    waitMinutes: 25,
  ),
  _ClinicArea(
    id: 'mastografia',
    name: 'Mastografia',
    icon: Icons.health_and_safety_outlined,
    locationHint: 'Primer piso, ala izquierda',
    waitMinutes: 18,
  ),
  _ClinicArea(
    id: 'farmacia',
    name: 'Farmacia',
    icon: Icons.local_pharmacy_outlined,
    locationHint: 'Planta baja, junto a la salida',
    waitMinutes: 10,
  ),
  _ClinicArea(
    id: 'consultorios',
    name: 'Consultorios',
    icon: Icons.medical_services_outlined,
    locationHint: 'Primer piso, pasillo central',
    waitMinutes: 30,
  ),
  _ClinicArea(
    id: 'caja',
    name: 'Caja',
    icon: Icons.point_of_sale_outlined,
    locationHint: 'Planta baja, junto a recepcion',
    waitMinutes: 8,
  ),
];

/// Mapeo de nombre de area (del estudio) a id de area del plano.
String? _matchAreaId(String? studyArea) {
  if (studyArea == null || studyArea.isEmpty) return null;
  final lower = studyArea.toLowerCase();
  if (lower.contains('rayos') || lower.contains('x')) return 'rayos_x';
  if (lower.contains('lab')) return 'laboratorio';
  if (lower.contains('ultra')) return 'ultrasonido';
  if (lower.contains('masto') || lower.contains('mamog')) return 'mastografia';
  if (lower.contains('farm')) return 'farmacia';
  if (lower.contains('consult')) return 'consultorios';
  if (lower.contains('caja')) return 'caja';
  if (lower.contains('recep')) return 'recepcion';
  return null;
}

/// Mapa para llegar a la sucursal del paciente. Toma la sucursal de la
/// reservacion activa (BD), muestra un mapa real de Google y, si existe
/// `mapa_geojson` en la BD, dibuja las areas internas. Si no hay cita
/// activa o falla la consulta, cae a Coyoacan (sucursal MVP) para que
/// el usuario nunca vea una pantalla vacia.
///
/// Si se recibe [studyId], se resalta el area correspondiente al estudio.
class ClinicMapPage extends ConsumerWidget {
  const ClinicMapPage({super.key, this.studyId});

  /// ID del estudio para resaltar su area en el plano.
  final String? studyId;

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
          highlightAreaId: null,
          highlightAreaHint: null,
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

          // Determinar area a resaltar basado en studyId o area activa.
          final areaName = status?.area ?? '';
          final matchedId = _matchAreaId(areaName);
          final matchedArea = matchedId != null
              ? _kDefaultAreas
                  .where((a) => a.id == matchedId)
                  .firstOrNull
              : null;

          return _Content(
            branch: branch,
            destinationLabel: areaName,
            isFallback: !hasActive,
            highlightAreaId: matchedId,
            highlightAreaHint: matchedArea?.locationHint,
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
    required this.highlightAreaId,
    required this.highlightAreaHint,
  });

  final Branch branch;
  final String destinationLabel;
  final bool isFallback;
  final String? highlightAreaId;
  final String? highlightAreaHint;

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
                      if (highlightAreaHint != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          highlightAreaHint!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
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
          error: (_, __) => _FloorPlanGrid(highlightAreaId: highlightAreaId),
          data: (b) {
            final geo = b.mapaGeojson;
            if (geo == null || ((geo['areas'] as List?)?.isEmpty ?? true)) {
              return _FloorPlanGrid(highlightAreaId: highlightAreaId);
            }
            return _IndoorMapView(branch: b);
          },
        ),
      ],
    );
  }
}

// ─── Floor Plan Grid (fallback when no GeoJSON) ────────────────────────────

class _FloorPlanGrid extends StatelessWidget {
  const _FloorPlanGrid({required this.highlightAreaId});
  final String? highlightAreaId;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: _kDefaultAreas.length,
      itemBuilder: (context, index) {
        final area = _kDefaultAreas[index];
        final isHighlighted = highlightAreaId == area.id;
        return _FloorPlanCard(area: area, isHighlighted: isHighlighted);
      },
    );
  }
}

class _FloorPlanCard extends StatefulWidget {
  const _FloorPlanCard({required this.area, required this.isHighlighted});
  final _ClinicArea area;
  final bool isHighlighted;

  @override
  State<_FloorPlanCard> createState() => _FloorPlanCardState();
}

class _FloorPlanCardState extends State<_FloorPlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isHighlighted) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _FloorPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isHighlighted && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final highlighted = widget.isHighlighted;

    final child = Container(
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.primary
              : AppColors.border,
          width: highlighted ? 2.0 : 1.0,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            area.icon,
            size: 28,
            color: highlighted ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            area.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              color: highlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '~${area.waitMinutes} min',
            style: TextStyle(
              fontSize: 11,
              color: highlighted
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
            ),
          ),
          if (highlighted) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tu destino',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (!highlighted) return child;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, c) => Transform.scale(
        scale: _pulseAnim.value,
        child: c,
      ),
      child: child,
    );
  }
}

// ─── Indoor Map (GeoJSON based) ─────────────────────────────────────────────

class _IndoorMapView extends StatelessWidget {
  const _IndoorMapView({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final geo = branch.mapaGeojson;
    if (geo == null) return _FloorPlanGrid(highlightAreaId: null);

    final areas = (geo['areas'] as List?) ?? const [];
    if (areas.isEmpty) return _FloorPlanGrid(highlightAreaId: null);

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
