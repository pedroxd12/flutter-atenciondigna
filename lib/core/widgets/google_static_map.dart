import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

/// Renderiza un mapa estatico de Google a traves del proxy del backend.
///
/// El backend (NestJS) firma la URL con la API key que vive en su `.env`
/// (`GOOGLE_MAPS_API`). El cliente nunca ve la key, lo que la mantiene
/// segura y permite revocarla/rotarla sin actualizar la app.
///
/// Si la API key no esta configurada en el servidor, el endpoint responde
/// 503 y este widget muestra un estado vacio en lugar de una imagen rota.
class GoogleStaticMap extends StatelessWidget {
  const GoogleStaticMap({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 14,
    this.height = 220,
    this.width,
    this.markers = const [],
    this.highlight,
    this.borderRadius = 20,
  });

  /// Coordenada central del mapa.
  final double lat;
  final double lng;

  /// Nivel de zoom (1-20). 14 ≈ barrio.
  final int zoom;

  final double height;
  final double? width;

  /// Pines secundarios (azul). Lista de `(lat, lng)`.
  final List<({double lat, double lng})> markers;

  /// Pin destacado (verde Salud Digna). Si es null, se usa el centro.
  final ({double lat, double lng})? highlight;

  final double borderRadius;

  String _buildUrl(int pixelWidth, int pixelHeight) {
    final base = AppConfig.apiBaseUrl;
    final params = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'zoom': zoom.toString(),
      'width': pixelWidth.toString(),
      'height': pixelHeight.toString(),
    };
    if (highlight != null) {
      params['highlight'] = '${highlight!.lat},${highlight!.lng}';
    }
    if (markers.isNotEmpty) {
      params['markers'] =
          markers.map((m) => '${m.lat},${m.lng}').join('|');
    }
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$base/maps/static?$qs';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (width ?? constraints.maxWidth).clamp(100.0, 1280.0);
        final h = height.clamp(100.0, 1280.0);
        final url = _buildUrl(w.round(), h.round());

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: w,
            height: h,
            color: const Color(0xFFE8EFF1),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const _MapEmptyState(),
            ),
          ),
        );
      },
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EFF1),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.map_outlined, size: 40, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text(
            'Mapa no disponible',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Verifica tu conexion o pide al equipo configurar el API de Google Maps en el servidor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
