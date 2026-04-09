import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/messages/patient_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/message_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/studies_providers.dart';

class PreparationsPage extends ConsumerWidget {
  const PreparationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studiesAsync = ref.watch(todaysStudiesProvider);
    final nombre =
        ref.watch(authControllerProvider).valueOrNull?.firstName ?? 'paciente';

    return Scaffold(
      appBar: AppBar(title: const Text('Preparaciones')),
      body: studiesAsync.when(
        data: (studies) {
          final withPrep =
              studies.where((s) => s.preparations.isNotEmpty).toList();
          if (withPrep.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 56,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin preparaciones pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$nombre, tus estudios de hoy no requieren preparacion especial.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final tips = PatientMessages.tipsForStudies(nombre, studies);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Recordatorio push
              const MessageBanner(
                message:
                    'Te enviaremos un recordatorio antes de cada estudio que requiera preparacion.',
                icon: Icons.notifications_active_outlined,
                style: MessageBannerStyle.info,
              ),
              const SizedBox(height: 14),

              // Orquestacion si aplica
              if (studies.any((s) => s.requiresPreparation) &&
                  studies.any((s) => !s.requiresPreparation))
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MessageBanner(
                    message: PatientMessages.preparationOrder(nombre),
                    icon: Icons.route_rounded,
                    style: MessageBannerStyle.tip,
                  ),
                ),

              // Tips de reglas de negocio relevantes
              if (tips.isNotEmpty) ...[
                MessageTipsList(tips: tips),
                const SizedBox(height: 6),
              ],

              // Estudios con preparaciones
              ...withPrep.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...s.preparations.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      p,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
