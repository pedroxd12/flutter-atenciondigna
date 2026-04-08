import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../location/providers/location_providers.dart';
import '../../domain/entities/branch.dart';
import '../providers/branches_providers.dart';

/// Pantalla "Mapas / Sucursales" — basada en mockup #4.
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(refreshLocationProvider.future));
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(nearestBranchesProvider(widget.idEstudio));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Selecciona una sucursal'),
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
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (branches) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(nearestBranchesProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFF1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Vista de mapa con tiempos\naproximados de cada\nsucursal de acuerdo al\ntipo de estudio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      left: 50,
                      child: _MapPin(selected: false),
                    ),
                    Positioned(
                      top: 80,
                      right: 60,
                      child: _MapPin(selected: false),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 80,
                      child: _MapPin(selected: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'CERCA DE TI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              ...branches.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BranchCard(
                    branch: b,
                    onTap: () {
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
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: selected ? 36 : 28,
      height: selected ? 36 : 28,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primaryDark : AppColors.primary,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.add,
        size: selected ? 20 : 16,
        color: selected ? Colors.white : AppColors.primary,
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch, required this.onTap});
  final Branch branch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      branch.address,
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
                  const SizedBox(height: 4),
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
