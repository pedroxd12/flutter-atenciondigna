import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SaturationChip extends StatelessWidget {
  const SaturationChip({super.key, required this.nivel, this.minutos});

  final String nivel; // bajo | medio | alto | critico
  final double? minutos;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSaturation(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            minutos == null
                ? nivel.toUpperCase()
                : '${minutos!.toStringAsFixed(0)} min · ${nivel.toUpperCase()}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
