import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/google_static_map.dart';
import '../../../location/providers/location_providers.dart';
import '../../../services/presentation/providers/catalog_providers.dart';
import '../../domain/entities/branch.dart';
import '../providers/branches_providers.dart';

/// Sucursal MVP por defecto cuando el backend no responde o el usuario
/// no concedio permisos de ubicacion. Coordenadas reales de Coyoacan.
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

/// Pantalla "Mapas / Sucursales" — muestra las sucursales mas cercanas
/// usando el catalogo de la BD y el mapa real de Google (proxy backend).
class BranchRecommendationPage extends ConsumerStatefulWidget {
  const BranchRecommendationPage({
    super.key,
    this.idEstudio = 2,
    this.selecting = false,
  });

  final int idEstudio;

  /// Si es true, al tocar una sucursal devuelve el `Branch` via context.pop.
  final bool selecting;

  @override
  ConsumerState<BranchRecommendationPage> createState() =>
      _BranchRecommendationPageState();
}

class _BranchRecommendationPageState
    extends ConsumerState<BranchRecommendationPage> {
  Branch? _selected;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(refreshLocationProvider.future));
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(currentPositionProvider);
    final branchesAsync = ref.watch(nearestBranchesProvider(widget.idEstudio));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Selecciona una sucursal'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(refreshLocationProvider.future);
              ref.invalidate(nearestBranchesProvider);
            },
          ),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Si el backend falla o las sucursales vienen vacias, NO bloqueamos
        // el mapa: caemos a la sucursal MVP (Coyoacan) y mostramos un banner
        // ligero invitando a activar la ubicacion para mejorar la precision.
        error: (e, _) => _buildBody(
          context,
          branches: const [_kCoyoacanFallback],
          showLocationBanner: position == null,
          isFallback: true,
        ),
        data: (branches) {
          final list = branches.isEmpty ? const [_kCoyoacanFallback] : branches;
          return _buildBody(
            context,
            branches: list,
            showLocationBanner: position == null,
            isFallback: branches.isEmpty,
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<Branch> branches,
    required bool showLocationBanner,
    required bool isFallback,
  }) {
    final position = ref.watch(currentPositionProvider);
    final selected = _selected ?? branches.first;
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(refreshLocationProvider.future);
        ref.invalidate(nearestBranchesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (showLocationBanner)
            _LocationBanner(
              onEnable: () async {
                await ref.read(refreshLocationProvider.future);
                ref.invalidate(nearestBranchesProvider);
              },
            ),
          if (showLocationBanner) const SizedBox(height: 14),
          _MapCard(
            center: selected,
            user: position,
            others: branches.where((b) => b.id != selected.id).toList(),
          ),
          const SizedBox(height: 18),
          _SectionLabel(isFallback ? 'SUCURSAL MVP' : 'CERCA DE TI'),
          const SizedBox(height: 10),
          ...branches.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BranchCard(
                branch: b,
                selected: b.id == selected.id,
                onTap: () => setState(() => _selected = b),
                onChoose: () {
                  if (widget.selecting) {
                    context.pop(b);
                  } else {
                    context.push('/checkin');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.onEnable});
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Activa tu ubicacion para ver las sucursales mas cercanas a ti.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onEnable,
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.center,
    required this.user,
    required this.others,
  });

  final Branch center;
  final dynamic user; // UserLocation? — evitamos import circular
  final List<Branch> others;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleStaticMap(
          lat: center.lat,
          lng: center.lng,
          zoom: 13,
          height: 220,
          highlight: (lat: center.lat, lng: center.lng),
          markers: [
            ...others.map((b) => (lat: b.lat, lng: b.lng)),
            if (user != null)
              (lat: user.lat as double, lng: user.lng as double),
          ],
        ),
        Positioned(
          left: 12,
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    center.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${center.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.selected,
    required this.onTap,
    required this.onChoose,
  });

  final Branch branch;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branch.address.isEmpty
                          ? 'Sin direccion en BD'
                          : branch.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tiempo aprox. ${branch.waitTimeMinutes.toStringAsFixed(0)} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${branch.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (selected)
                    FilledButton(
                      onPressed: onChoose,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Elegir'),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }
}

