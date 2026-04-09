import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/messages/patient_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/message_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../studies/presentation/providers/studies_providers.dart';
import '../../domain/entities/wait_status.dart';
import '../providers/waiting_providers.dart';

/// Sala de espera — toma toda la informacion de la BD via WaitingService.
/// Sin folios inventados ni nombres falsos: si no hay cola, muestra el
/// estado vacio correspondiente.
class LiveWaitingPage extends ConsumerWidget {
  const LiveWaitingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(waitStatusStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sala de espera'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: 'No pudimos obtener tu estado de espera',
          onRetry: () => ref.invalidate(waitStatusStreamProvider),
        ),
        data: (status) {
          if (!status.hasActiveService) return const _NoActiveAppointment();
          if (status.isYourTurn) return _YourTurnView(status: status);
          return _WaitingBody(status: status);
        },
      ),
    );
  }
}

class _WaitingBody extends ConsumerWidget {
  const _WaitingBody({required this.status});
  final WaitStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(waitQueueProvider);
    final nombre =
        ref.watch(authControllerProvider).valueOrNull?.firstName ?? 'paciente';
    final studiesAsync = ref.watch(todaysStudiesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(waitQueueProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Folio o aviso de check-in
          if (status.folio != null)
            Center(
              child: Column(
                children: [
                  const Text(
                    'TU FOLIO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.folio!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          if (status.folio == null)
            MessageBanner(
              message:
                  'Aun no se asigna folio. Acude a recepcion o realiza tu check-in.',
              style: MessageBannerStyle.warning,
            ),

          const SizedBox(height: 16),

          // Mensaje de estimacion de tiempo
          MessageBanner(
            message: PatientMessages.timeEstimate(
              nombre,
              status.estimatedMinutes.toInt(),
            ),
            icon: Icons.timer_outlined,
            style: MessageBannerStyle.success,
          ),

          const SizedBox(height: 16),

          // Estudio actual
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Text(
                  'SIGUIENTE ESTUDIO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status.currentStudy,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  status.area,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Posicion y tiempo
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'Tiempo estimado',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${status.estimatedMinutes.toStringAsFixed(0)} min',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'Tu posicion',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '#${status.peopleAhead + 1} en la fila',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mensaje de "mantente atento"
          MessageBanner(
            message: PatientMessages.stayAlert(nombre),
            icon: Icons.phone_android_rounded,
            style: MessageBannerStyle.info,
          ),

          const SizedBox(height: 20),

          // Tips contextuales segun estudios
          studiesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (studies) {
              final tips = PatientMessages.tipsForStudies(nombre, studies);
              if (tips.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFORMACION IMPORTANTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MessageTipsList(tips: tips),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),

          // Lista de espera
          const Text(
            'LISTA DE ESPERA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          queueAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const _InlineEmpty(
              icon: Icons.info_outline,
              text: 'No pudimos cargar la lista de espera',
            ),
            data: (queue) {
              if (queue.isEmpty) {
                return const _InlineEmpty(
                  icon: Icons.people_outline,
                  text: 'Aun no hay otros pacientes en la cola',
                );
              }
              return Column(
                children: queue
                    .map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PatientRow(item: q),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.item});
  final QueueItem item;

  @override
  Widget build(BuildContext context) {
    final highlight = item.isMine;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: highlight
                ? AppColors.primary
                : AppColors.inputFill,
            child: Text(
              item.initials,
              style: TextStyle(
                color: highlight ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isMine ? 'Tu turno' : 'Folio ${item.folio}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.isCurrent ? 'En atencion ahora' : item.estudio,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.isCurrent
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.isCurrent ? 'En atencion' : 'Posicion ${item.posicion}',
              style: TextStyle(
                color: item.isCurrent
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YourTurnView extends ConsumerWidget {
  const _YourTurnView({required this.status});
  final WaitStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre =
        ref.watch(authControllerProvider).valueOrNull?.firstName ?? 'paciente';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$nombre, es tu turno!',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            status.area.isEmpty
                ? 'Acude al consultorio asignado'
                : 'Dirigete a ${status.area}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/clinic-map'),
              icon: const Icon(Icons.directions_walk),
              label: const Text('Como llego'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActiveAppointment extends StatelessWidget {
  const _NoActiveAppointment();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes una cita activa',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando agendes y hagas check-in en una sucursal veras tu posicion en la sala de espera.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.push('/request-service'),
              icon: const Icon(Icons.add_circle),
              label: const Text('Solicitar un estudio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
