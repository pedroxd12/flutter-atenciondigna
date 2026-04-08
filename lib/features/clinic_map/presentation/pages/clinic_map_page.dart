import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mapa interno simplificado de la clinica.
///
/// Implementacion: CustomPaint con un layout esquematico de areas.
/// La logica de "destino actual" vendria de WaitStatus.area.
class ClinicMapPage extends StatelessWidget {
  const ClinicMapPage({
    super.key,
    this.destinationArea = 'Area 2 - Laboratorio',
  });

  final String destinationArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de la clinica')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
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
                        destinationArea,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: _ClinicLayoutPainter(),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _Legend(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendDot(AppColors.primary, 'Tu ubicacion'),
        _legendDot(AppColors.saturationCritical, 'Destino'),
        _legendDot(AppColors.textSecondary, 'Otras areas'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ClinicLayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Offset.zero & size, bg);

    // Areas (rectangulos esquematicos)
    final areas = [
      _Area('Recepcion', const Rect.fromLTWH(20, 20, 120, 80), false),
      _Area('Sala de espera', const Rect.fromLTWH(150, 20, 200, 80), false),
      _Area('Laboratorio', const Rect.fromLTWH(20, 110, 150, 100), true),
      _Area('Rayos X', const Rect.fromLTWH(180, 110, 170, 100), false),
      _Area('Ultrasonido', const Rect.fromLTWH(20, 220, 150, 90), false),
      _Area('Consultorios', const Rect.fromLTWH(180, 220, 170, 90), false),
    ];

    for (final area in areas) {
      final fill = Paint()
        ..color = area.isDestination
            ? AppColors.saturationCritical.withValues(alpha: 0.18)
            : Colors.white;
      final stroke = Paint()
        ..color = area.isDestination
            ? AppColors.saturationCritical
            : AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = area.isDestination ? 2.5 : 1;

      final rrect = RRect.fromRectAndRadius(area.rect, const Radius.circular(8));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);

      final tp = TextPainter(
        text: TextSpan(
          text: area.label,
          style: TextStyle(
            color: area.isDestination
                ? AppColors.saturationCritical
                : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: area.isDestination
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(maxWidth: area.rect.width - 8);
      tp.paint(
        canvas,
        Offset(
          area.rect.center.dx - tp.width / 2,
          area.rect.center.dy - tp.height / 2,
        ),
      );
    }

    // "Tu ubicacion" — punto en recepcion
    final you = Paint()..color = AppColors.primary;
    canvas.drawCircle(const Offset(80, 60), 6, you);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Area {
  _Area(this.label, this.rect, this.isDestination);
  final String label;
  final Rect rect;
  final bool isDestination;
}
