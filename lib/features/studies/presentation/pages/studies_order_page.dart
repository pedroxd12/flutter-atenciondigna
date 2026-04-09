import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/messages/patient_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/message_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../waiting/presentation/providers/waiting_providers.dart';
import '../../domain/entities/study.dart';
import '../providers/studies_providers.dart';

/// Pantalla unificada de "Estudios" — muestra el estado de espera en vivo
/// cuando hay cita activa, o un empty state invitando a explorar el catalogo.
class StudiesOrderPage extends ConsumerWidget {
  const StudiesOrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studiesAsync = ref.watch(todaysStudiesProvider);
    final nombre =
        ref.watch(authControllerProvider).valueOrNull?.firstName ?? 'paciente';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis estudios'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: studiesAsync.when(
        data: (studies) {
          if (studies.isEmpty) return _EmptyState(nombre: nombre);
          return _StudiesWithWaiting(studies: studies, nombre: nombre);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty state — sin estudios
// ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.science_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No tienes estudios\npor el momento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$nombre, explora nuestro catalogo y comienza a hacer digna tu salud.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/services'),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Explorar catalogo'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/request-service'),
              child: const Text('Ya tengo una orden medica'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Vista con estudios activos + estado de espera
// ─────────────────────────────────────────────────────────

class _StudiesWithWaiting extends ConsumerWidget {
  const _StudiesWithWaiting({required this.studies, required this.nombre});
  final List<Study> studies;
  final String nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitAsync = ref.watch(waitStatusStreamProvider);
    final total = studies.fold<double>(0, (acc, s) => acc + s.estimatedMinutes);
    final tips = PatientMessages.tipsForStudies(nombre, studies);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // ── Estado de espera en vivo (si aplica) ──
        waitAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (status) {
            if (!status.hasActiveService) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => context.push('/waiting'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: status.isYourTurn
                        ? AppColors.primary
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                    border: status.isYourTurn
                        ? null
                        : Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: status.isYourTurn
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status.isYourTurn
                              ? Icons.notifications_active
                              : Icons.schedule,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.isYourTurn
                                  ? '$nombre, es tu turno!'
                                  : '${status.peopleAhead} persona${status.peopleAhead != 1 ? 's' : ''} antes que tu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: status.isYourTurn
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status.isYourTurn
                                  ? 'Dirigete a ${status.area}'
                                  : '~${status.estimatedMinutes.toStringAsFixed(0)} min · ${status.currentStudy}',
                              style: TextStyle(
                                fontSize: 13,
                                color: status.isYourTurn
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: status.isYourTurn
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // ── Estimacion de tiempo ──
        MessageBanner(
          message: PatientMessages.timeEstimate(nombre, total.toInt()),
          icon: Icons.timer_outlined,
          style: MessageBannerStyle.success,
        ),
        const SizedBox(height: 20),

        // ── Encabezado ──
        Text(
          '${studies.length} estudio${studies.length > 1 ? 's' : ''} programado${studies.length > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'El orden esta optimizado para que termines lo antes posible.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // ── Timeline de estudios ──
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

        // ── Tips contextuales ──
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'INFORMACION PARA TUS ESTUDIOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          MessageTipsList(tips: tips),
        ],

        const SizedBox(height: 16),
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
  }
}

// ─────────────────────────────────────────────────────────
// Componentes compartidos
// ─────────────────────────────────────────────────────────

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
