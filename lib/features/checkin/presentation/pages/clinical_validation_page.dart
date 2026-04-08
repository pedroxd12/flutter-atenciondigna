import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/checkin_pass.dart';
import '../providers/checkin_providers.dart';

class ClinicalValidationPage extends ConsumerStatefulWidget {
  const ClinicalValidationPage({super.key});

  @override
  ConsumerState<ClinicalValidationPage> createState() =>
      _ClinicalValidationPageState();
}

class _ClinicalValidationPageState
    extends ConsumerState<ClinicalValidationPage> {
  bool _hasMedicalOrder = false;
  bool _sampleRecent = true;
  ClinicalValidation? _result;
  bool _validating = false;

  Future<void> _validate() async {
    setState(() {
      _validating = true;
      _result = null;
    });

    final remote = ref.read(checkinRemoteProvider);
    final res = await remote.validateClinicalRules(
      studyIds: const [2, 5, 6],
      hasMedicalOrder: _hasMedicalOrder,
      sampleCollectedAt: _sampleRecent
          ? DateTime.now().subtract(const Duration(minutes: 30))
          : DateTime.now().subtract(const Duration(hours: 3)),
    );

    setState(() {
      _result = res;
      _validating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validacion clinica')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Confirma estos datos antes de tu check-in. Si algo falla, recepcion no podra registrarte.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _hasMedicalOrder,
                  onChanged: (v) => setState(() => _hasMedicalOrder = v),
                  title: const Text('Tengo mi orden medica'),
                  subtitle: const Text(
                    'Necesaria para Rayos X, Ultrasonido, Tomografia y RM',
                  ),
                  activeThumbColor: AppColors.primary,
                ),
                const Divider(height: 1, color: AppColors.border),
                SwitchListTile(
                  value: _sampleRecent,
                  onChanged: (v) => setState(() => _sampleRecent = v),
                  title: const Text('Mi muestra de orina es de hace < 2 h'),
                  subtitle: const Text(
                    'Si es mas vieja, debes recolectar una nueva',
                  ),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _validating ? null : _validate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(54),
            ),
            child: _validating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Text('Validar y continuar'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ValidationResult(
              result: _result!,
              onContinue: () => context.go('/home/waiting'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValidationResult extends StatelessWidget {
  const _ValidationResult({required this.result, required this.onContinue});

  final ClinicalValidation result;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final color = result.isOk
        ? AppColors.saturationLow
        : AppColors.saturationCritical;
    final icon = result.isOk
        ? Icons.check_circle
        : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (result.isOk) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Ir a sala de espera'),
            ),
          ],
        ],
      ),
    );
  }
}
