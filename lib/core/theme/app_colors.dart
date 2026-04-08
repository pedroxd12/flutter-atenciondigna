import 'package:flutter/material.dart';

/// Paleta de Atencion Digna — derivada del branding de Salud Digna.
/// Pensada para alto contraste y legibilidad de adultos mayores.
class AppColors {
  AppColors._();

  // Verdes Salud Digna
  static const Color primary = Color(0xFF1FA45A); // verde Salud Digna
  static const Color primaryDark = Color(0xFF0F7A3F);
  static const Color primarySoft = Color(0xFFE8F6EE);

  static const Color secondary = Color(0xFF1E3A5F);

  // Neutros
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputFill = Color(0xFFF1F3F5);

  // Niveles de saturacion
  static const Color saturationLow = Color(0xFF22C55E);
  static const Color saturationMedium = Color(0xFFF59E0B);
  static const Color saturationHigh = Color(0xFFF97316);
  static const Color saturationCritical = Color(0xFFDC2626);

  // Estados
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

  static Color forSaturation(String nivel) {
    switch (nivel) {
      case 'bajo':
        return saturationLow;
      case 'medio':
        return saturationMedium;
      case 'alto':
        return saturationHigh;
      case 'critico':
        return saturationCritical;
      default:
        return textSecondary;
    }
  }
}
