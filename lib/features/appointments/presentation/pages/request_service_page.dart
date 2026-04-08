import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../branches/domain/entities/branch.dart';
import '../../../studies/domain/entities/study_catalog_item.dart';
import '../../../studies/presentation/providers/studies_providers.dart';
import '../providers/appointments_providers.dart';

/// Flujo simple en 3 pasos pensado para adultos mayores:
///   1. Elegir tipo de estudio (catalogo viene 100% de la BD)
///   2. Elegir sucursal (sucursales reales con su tiempo de espera)
///   3. Elegir fecha y confirmar
class RequestServicePage extends ConsumerStatefulWidget {
  const RequestServicePage({super.key});

  @override
  ConsumerState<RequestServicePage> createState() => _RequestServicePageState();
}

class _RequestServicePageState extends ConsumerState<RequestServicePage> {
  final List<int> _selectedStudies = [];
  Branch? _branch;
  DateTime? _date;
  bool _submitting = false;

  bool get _canSubmit =>
      _selectedStudies.isNotEmpty && _branch != null && _date != null;

  Future<void> _pickBranch() async {
    if (_selectedStudies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero elige al menos un estudio')),
      );
      return;
    }
    final result = await context.push<Branch>(
      '/branches?selecting=1&id_estudio=${_selectedStudies.first}',
    );
    if (result != null) {
      setState(() => _branch = result);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Elige el dia',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final create = ref.read(createAppointmentProvider);
      await create(
        CreateAppointmentParams(
          branchId: _branch!.id,
          date: DateFormat('yyyy-MM-dd').format(_date!),
          time: '09:00',
          studyIds: _selectedStudies,
        ),
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Listo'),
          content: const Text(
            'Tu cita fue agendada. Te avisaremos antes de la hora.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  IconData _iconFor(String nombre) {
    final n = nombre.toUpperCase();
    if (n.contains('LABORATORIO')) return Icons.science;
    if (n.contains('RAYOS')) return Icons.medical_information;
    if (n.contains('ULTRASONIDO')) return Icons.monitor_heart;
    if (n.contains('MASTOGRAFIA')) return Icons.favorite_border;
    if (n.contains('ELECTRO')) return Icons.favorite;
    if (n.contains('PAPANICOLAOU')) return Icons.female;
    if (n.contains('DENSITO')) return Icons.accessibility_new;
    if (n.contains('NUTRI')) return Icons.restaurant;
    if (n.contains('TOMOGRAFIA')) return Icons.scanner;
    if (n.contains('RESONANCIA')) return Icons.hub;
    if (n.contains('OPTICA')) return Icons.visibility;
    return Icons.local_hospital;
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(studiesCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Solicitar estudio')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _StepHeader(
            number: 1,
            title: 'Que estudio necesitas?',
            done: _selectedStudies.isNotEmpty,
          ),
          const SizedBox(height: 12),
          catalogAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _CatalogError(
              onRetry: () => ref.invalidate(studiesCatalogProvider),
            ),
            data: (catalog) {
              if (catalog.isEmpty) {
                return const _EmptyCatalog();
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: catalog
                    .map((s) => _StudyChip(
                          item: s,
                          icon: _iconFor(s.nombre),
                          selected: _selectedStudies.contains(s.id),
                          onTap: () => setState(() {
                            if (_selectedStudies.contains(s.id)) {
                              _selectedStudies.remove(s.id);
                            } else {
                              _selectedStudies.add(s.id);
                            }
                          }),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          _StepHeader(number: 2, title: 'Donde?', done: _branch != null),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.local_hospital,
                color: AppColors.primary,
              ),
              title: Text(
                _branch?.name ?? 'Elegir sucursal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: _branch != null
                  ? Text(
                      '${_branch!.distanceKm.toStringAsFixed(1)} km · ~${_branch!.waitTimeMinutes.toStringAsFixed(0)} min',
                    )
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickBranch,
            ),
          ),
          const SizedBox(height: 24),
          _StepHeader(
            number: 3,
            title: 'Cuando?',
            done: _date != null,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              title: Text(
                _date == null
                    ? 'Elegir fecha'
                    : DateFormat("EEEE d 'de' MMMM", 'es').format(_date!),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _canSubmit && !_submitting ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.6,
                    ),
                  )
                : const Text('Confirmar cita'),
          ),
        ],
      ),
    );
  }
}

class _StudyChip extends StatelessWidget {
  const _StudyChip({
    required this.item,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final StudyCatalogItem item;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _capitalize(item.nombre),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (item.requiereOrdenMedica) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: selected ? Colors.white : AppColors.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.number,
    required this.title,
    required this.done,
  });
  final int number;
  final String title;
  final bool done;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done ? AppColors.primary : AppColors.inputFill,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text(
                  '$number',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay estudios registrados en la base de datos.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No pudimos cargar el catalogo de estudios.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
