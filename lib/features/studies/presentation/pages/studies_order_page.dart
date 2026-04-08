import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/study.dart';
import '../providers/studies_providers.dart';

class StudiesOrderPage extends ConsumerWidget {
  const StudiesOrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studiesAsync = ref.watch(todaysStudiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis estudios de hoy')),
      body: studiesAsync.when(
        data: (studies) {
          final total = studies.fold<double>(
            0,
            (acc, s) => acc + s.estimatedMinutes,
          );
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(
                title: '${studies.length} estudios',
                subtitle:
                    'Tiempo total estimado: ${total.toStringAsFixed(0)} min · orden calculado por el motor de reglas',
              ),
              const SizedBox(height: 20),
              ...studies.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _StudyTimelineCard(
                    index: e.key + 1,
                    study: e.value,
                    isLast: e.key == studies.length - 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push('/preparations'),
                icon: const Icon(Icons.checklist_rtl),
                label: const Text('Ver preparaciones'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StudyTimelineCard extends StatelessWidget {
  const _StudyTimelineCard({
    required this.index,
    required this.study,
    required this.isLast,
  });

  final int index;
  final Study study;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      study.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      study.area,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          icon: Icons.schedule,
                          label:
                              '~${study.estimatedMinutes.toStringAsFixed(0)} min',
                        ),
                        if (study.requiresPreparation)
                          const _Pill(
                            icon: Icons.no_food_outlined,
                            label: 'Preparacion',
                            color: AppColors.saturationMedium,
                          ),
                        if (study.requiresMedicalOrder)
                          const _Pill(
                            icon: Icons.assignment_outlined,
                            label: 'Orden medica',
                            color: AppColors.saturationHigh,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
