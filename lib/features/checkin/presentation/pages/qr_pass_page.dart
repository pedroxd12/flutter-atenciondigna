import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/messages/patient_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/message_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../studies/presentation/providers/studies_providers.dart';
import '../providers/checkin_providers.dart';

/// Mi pase de entrada — diseño basado en el mockup "Codigo QR".
class QrPassPage extends ConsumerWidget {
  const QrPassPage({super.key, required this.branchId});

  final int branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(currentPatientIdProvider);
    final studiesAsync = ref.watch(todaysStudiesProvider);

    if (patientId == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesion para ver tu pase')),
      );
    }

    return studiesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (studies) {
        final studyIds = studies.map((s) => s.id).toList();
        final mainStudy = studies.isNotEmpty ? studies.first.name : 'Estudio';
        final passAsync = ref.watch(
          checkinPassProvider(
            CheckinPassParams(
              patientId: patientId,
              branchId: branchId,
              studyIds: studyIds,
            ),
          ),
        );

        final patient =
            ref.watch(authControllerProvider).valueOrNull;
        final nombre = patient?.firstName ?? 'paciente';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mi pase de entrada'),
          ),
          body: passAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (pass) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Mensaje de bienvenida
                  MessageBanner(
                    message: PatientMessages.welcome(
                      nombre,
                      'Coyoacan',
                    ),
                    icon: Icons.waving_hand_rounded,
                    style: MessageBannerStyle.success,
                  ),
                  const SizedBox(height: 20),

                  // Titulo
                  const Text(
                    'Tu cita confirmada',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mainStudy,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Hora + ubicacion
                  Card(
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Fecha y hora',
                          value: DateFormat(
                            "d 'de' MMMM, h:mm a",
                            'es',
                          ).format(pass.issuedAt),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _InfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Ubicacion',
                          value: 'Sucursal #${pass.branchId}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // QR
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: pass.toQrPayload(),
                          version: QrVersions.auto,
                          size: 200,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.textPrimary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Valido hasta ${DateFormat('h:mm a').format(pass.expiresAt)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pasos sencillos
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUE HACER AHORA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 14),
                        _Step(
                          number: 1,
                          text: 'Acercate al area de recepcion',
                        ),
                        SizedBox(height: 12),
                        _Step(
                          number: 2,
                          text: 'Escanea este codigo QR',
                        ),
                        SizedBox(height: 12),
                        _Step(
                          number: 3,
                          text: 'Espera tu turno en la app',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/clinical-validation'),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Continuar al check-in'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Ayuda'),
                      ),
                      const Text(
                        '·',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Cancelar / Reprogramar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
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
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
