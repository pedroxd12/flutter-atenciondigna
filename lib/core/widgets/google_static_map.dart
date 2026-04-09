import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Mapa estatico basado en tiles de OpenStreetMap.
///
/// **No requiere API key ni proxy del backend.** Renderiza un mosaico de
/// tiles OSM (3x3 por defecto) centrado en `(lat, lng)` con un marcador
/// dibujado encima. Esto reemplaza al antiguo proxy de Google Maps que
/// dependia de `GOOGLE_MAPS_API` en el servidor (devolvia 503 si la key
/// no estaba configurada y bloqueaba el mapa).
///
/// Marcas:
///   - `highlight`: pin verde Salud Digna (centro por defecto).
///   - `markers`: pines azules secundarios.
///
/// El nombre `GoogleStaticMap` se mantiene para no romper imports
/// existentes en la app.
class GoogleStaticMap extends StatelessWidget {
  const GoogleStaticMap({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 15,
    this.height = 220,
    this.width,
    this.markers = const [],
    this.highlight,
    this.borderRadius = 20,
  });

  final double lat;
  final double lng;
  final int zoom;
  final double height;
  final double? width;
  final List<({double lat, double lng})> markers;
  final ({double lat, double lng})? highlight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (width ?? constraints.maxWidth).clamp(100.0, 1280.0);
        final h = height.clamp(100.0, 1280.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _OsmTileMosaic(lat: lat, lng: lng, zoom: zoom),
                CustomPaint(
                  painter: _MarkersPainter(
                    centerLat: lat,
                    centerLng: lng,
                    zoom: zoom,
                    highlight: highlight ?? (lat: lat, lng: lng),
                    markers: markers,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.white.withValues(alpha: 0.7),
                    child: const Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Tile mosaic
// ──────────────────────────────────────────────

/// Renderiza una matriz 3x3 de tiles OSM centrada en (lat, lng) al zoom
/// pedido. La matriz cubre suficiente area para que el centro siempre
/// quede visible aunque la pantalla sea grande.
class _OsmTileMosaic extends StatelessWidget {
  const _OsmTileMosaic({
    required this.lat,
    required this.lng,
    required this.zoom,
  });

  final double lat;
  final double lng;
  final int zoom;

  static const int _gridRadius = 1; // 3x3 tiles
  static const double _tileSize = 256.0;

  @override
  Widget build(BuildContext context) {
    final centerTile = _latLngToTile(lat, lng, zoom);
    final centerXFrac = centerTile.xFrac;
    final centerYFrac = centerTile.yFrac;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Coordenada del centro del viewport en pixels respecto al tile
        // central.
        final centerPxX = constraints.maxWidth / 2;
        final centerPxY = constraints.maxHeight / 2;

        final children = <Widget>[];
        for (int dy = -_gridRadius; dy <= _gridRadius; dy++) {
          for (int dx = -_gridRadius; dx <= _gridRadius; dx++) {
            final tx = centerTile.x + dx;
            final ty = centerTile.y + dy;
            // Coord del top-left del tile, alineando el centro del tile
            // central con el centro del viewport.
            final px = centerPxX -
                centerXFrac * _tileSize +
                dx * _tileSize;
            final py = centerPxY -
                centerYFrac * _tileSize +
                dy * _tileSize;
            children.add(
              Positioned(
                left: px,
                top: py,
                width: _tileSize,
                height: _tileSize,
                child: Image.network(
                  'https://tile.openstreetmap.org/$zoom/$tx/$ty.png',
                  fit: BoxFit.cover,
                  headers: const {
                    // OSM exige un User-Agent identificable. Flutter en
                    // Android no permite sobrescribir UA, pero pasarlo
                    // como header satisface la mayoria de sus reglas.
                    'User-Agent': 'AtencionDignaApp/1.0',
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            );
          }
        }
        return Container(
          color: const Color(0xFFE8EFF1),
          child: Stack(clipBehavior: Clip.hardEdge, children: children),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Markers
// ──────────────────────────────────────────────

class _MarkersPainter extends CustomPainter {
  _MarkersPainter({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.highlight,
    required this.markers,
  });

  final double centerLat;
  final double centerLng;
  final int zoom;
  final ({double lat, double lng}) highlight;
  final List<({double lat, double lng})> markers;

  @override
  void paint(Canvas canvas, Size size) {
    // Pines secundarios (azules)
    for (final m in markers) {
      final p = _project(m.lat, m.lng, size);
      _drawPin(canvas, p, AppColors.primary.withValues(alpha: 0.85), 12);
    }
    // Pin destacado (verde / rojo brand)
    final hp = _project(highlight.lat, highlight.lng, size);
    _drawPin(canvas, hp, const Color(0xFFDC2626), 18);
  }

  Offset _project(double lat, double lng, Size size) {
    final c = _latLngToTile(centerLat, centerLng, zoom);
    final p = _latLngToTile(lat, lng, zoom);
    final dxTiles = (p.x + p.xFrac) - (c.x + c.xFrac);
    final dyTiles = (p.y + p.yFrac) - (c.y + c.yFrac);
    final dx = dxTiles * 256.0;
    final dy = dyTiles * 256.0;
    return Offset(size.width / 2 + dx, size.height / 2 + dy);
  }

  void _drawPin(Canvas canvas, Offset p, Color color, double radius) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(p, radius + 1, shadow);

    final fill = Paint()..color = color;
    canvas.drawCircle(p, radius, fill);

    final hole = Paint()..color = Colors.white;
    canvas.drawCircle(p, radius * 0.4, hole);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ──────────────────────────────────────────────
// Helpers — proyeccion Mercator slippy tiles
// ──────────────────────────────────────────────

class _TilePos {
  const _TilePos(this.x, this.y, this.xFrac, this.yFrac);
  final int x;
  final int y;
  final double xFrac; // 0..1 — posicion dentro del tile
  final double yFrac;
}

_TilePos _latLngToTile(double lat, double lng, int zoom) {
  final n = math.pow(2, zoom).toDouble();
  final xFloat = (lng + 180.0) / 360.0 * n;
  final latRad = lat * math.pi / 180.0;
  final yFloat = (1.0 -
          math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
      2.0 *
      n;
  final x = xFloat.floor();
  final y = yFloat.floor();
  return _TilePos(x, y, xFloat - x, yFloat - y);
}
