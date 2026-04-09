import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../appointments/presentation/providers/appointments_providers.dart';
import '../../data/salud_digna_catalog.dart';
import '../providers/catalog_providers.dart';
import 'services_categories_page.dart' show capitalizeWords;

/// Carrito de servicios + agendamiento con horarios reales.
///
/// Flujo:
///   1. El paciente revisa los servicios que selecciono.
///   2. Elige una fecha (selector nativo).
///   3. La app pide al backend la lista de horarios disponibles ese dia
///      (`GET /reservaciones/slots`). Cada slot trae su tiempo total
///      estimado y nivel de saturacion calculados por el modelo de IA
///      (XGBoost + scheduler global).
///   4. El paciente elige UN horario de la lista y confirma.
///   5. Se crea la reservacion con `POST /reservaciones` usando esa hora.
class ServiceCartPage extends ConsumerStatefulWidget {
  const ServiceCartPage({super.key});

  @override
  ConsumerState<ServiceCartPage> createState() => _ServiceCartPageState();
}

class _ServiceCartPageState extends ConsumerState<ServiceCartPage> {
  DateTime _date = DateTime.now();
  AvailableSlot? _selectedSlot;
  bool _submitting = false;
  Map<String, dynamic>? _result;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'Cuando quieres agendar?',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _selectedSlot = null; // resetea seleccion al cambiar de dia
      });
    }
  }

  Future<void> _confirm() async {
    final cart = ref.read(serviceCartProvider);
    final slot = _selectedSlot;
    if (cart.totalItems == 0 || slot == null) return;
    setState(() => _submitting = true);
    try {
      final create = ref.read(createAppointmentProvider);
      final appt = await create(
        CreateAppointmentParams(
          branchId: CoyoacanBranch.id,
          date: slot.date,
          time: slot.time,
          studyIds: slot.orderedStudyIds.isNotEmpty
              ? slot.orderedStudyIds
              : cart.idsEstudio,
        ),
      );
      if (!mounted) return;
      setState(() {
        _result = {
          'id': appt.id,
          'date': appt.date,
          'time': appt.time ?? slot.time,
          'estimatedMin': slot.totalEstimatedMin,
          'saturation': slot.saturationLevel,
          'reason': slot.reason,
        };
      });
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

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(serviceCartProvider);
    final money = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tu cita'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: cart.totalItems == 0
          ? const _EmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              children: [
                const _BranchCard(),
                const SizedBox(height: 14),
                const _SectionLabel('Servicios seleccionados'),
                const SizedBox(height: 8),
                ...cart.items.map(
                  (i) => _CartItemTile(
                    item: i,
                    onRemove: () =>
                        ref.read(serviceCartProvider.notifier).toggle(i),
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  total: cart.total,
                  count: cart.totalItems,
                  money: money,
                ),
                const SizedBox(height: 18),
                if (_result == null) ...[
                  const _SectionLabel('Cuando quieres agendar?'),
                  const SizedBox(height: 8),
                  _DateCard(date: _date, onTap: _pickDate),
                  const SizedBox(height: 18),
                  const _SectionLabel('Horarios disponibles'),
                  const SizedBox(height: 8),
                  _SlotsSection(
                    branchId: CoyoacanBranch.id,
                    date: DateFormat('yyyy-MM-dd').format(_date),
                    studyIds: cart.idsEstudio,
                    selected: _selectedSlot,
                    onSelect: (s) => setState(() => _selectedSlot = s),
                  ),
                  const SizedBox(height: 16),
                  _PreparationsRecap(idsEstudio: cart.idsEstudio),
                ] else
                  _ConfirmedCard(result: _result!),
              ],
            ),
      bottomNavigationBar: cart.totalItems == 0
          ? null
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: _result == null
                    ? FilledButton.icon(
                        onPressed: (_selectedSlot == null || _submitting)
                            ? null
                            : _confirm,
                        icon: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Icon(Icons.event_available),
                        label: Text(
                          _selectedSlot == null
                              ? 'Elige un horario'
                              : 'Confirmar a las ${_selectedSlot!.time}',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () {
                          ref.read(serviceCartProvider.notifier).clear();
                          context.go('/home');
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Listo, ir al inicio'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: AppColors.success,
                        ),
                      ),
              ),
            ),
    );
  }
}

// ──────────────────────────────────────────────
// Slots picker
// ──────────────────────────────────────────────

class _SlotsSection extends ConsumerWidget {
  const _SlotsSection({
    required this.branchId,
    required this.date,
    required this.studyIds,
    required this.selected,
    required this.onSelect,
  });

  final int branchId;
  final String date;
  final List<int> studyIds;
  final AvailableSlot? selected;
  final ValueChanged<AvailableSlot> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = SlotsQuery(
      branchId: branchId,
      date: date,
      studyIds: studyIds,
    );
    final async = ref.watch(availableSlotsProvider(query));

    return async.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _SlotsError(
        message: 'No pudimos cargar horarios disponibles',
        detail: e.toString(),
        onRetry: () => ref.invalidate(availableSlotsProvider(query)),
      ),
      data: (slots) {
        if (slots.isEmpty) {
          return _SlotsError(
            message: 'No hay horarios disponibles este dia',
            detail: 'Intenta con otra fecha o reduce los servicios.',
            onRetry: () => ref.invalidate(availableSlotsProvider(query)),
          );
        }
        return Column(
          children: [
            for (final s in slots)
              _SlotTile(
                slot: s,
                selected: selected?.hour == s.hour && selected?.date == s.date,
                onTap: () => onSelect(s),
              ),
          ],
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final AvailableSlot slot;
  final bool selected;
  final VoidCallback onTap;

  Color get _satColor {
    switch (slot.saturationLevel) {
      case 'bajo':
        return const Color(0xFF059669);
      case 'medio':
        return const Color(0xFFD97706);
      case 'alto':
        return const Color(0xFFDC2626);
      case 'critico':
        return const Color(0xFF991B1B);
    }
    return const Color(0xFFD97706);
  }

  String get _satLabel {
    switch (slot.saturationLevel) {
      case 'bajo':
        return 'Poca espera';
      case 'medio':
        return 'Espera moderada';
      case 'alto':
        return 'Mucha demanda';
      case 'critico':
        return 'Saturado';
    }
    return slot.saturationLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    slot.time,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '~${slot.totalEstimatedMin.toStringAsFixed(0)} min en total',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${slot.waitMin} min de espera + ${slot.serviceMin} min de atencion',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _satColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _satLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: _satColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (slot.reason.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '· ${slot.reason}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotsError extends StatelessWidget {
  const _SlotsError({
    required this.message,
    required this.detail,
    required this.onRetry,
  });
  final String message;
  final String detail;
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
      child: Column(
        children: [
          const Icon(
            Icons.event_busy,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Resto de widgets de la pagina
// ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_hospital, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salud Digna Coyoacan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Av. Universidad 1330, Del Valle',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  'Horario: 7:00 - 20:00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.onRemove});
  final CatalogItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              capitalizeWords(item.nombre),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          if (item.precio != null) ...[
            const SizedBox(width: 8),
            Text(
              money.format(item.precio),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
        title: const Text(
          'Dia de la cita',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          DateFormat("EEEE d 'de' MMMM", 'es').format(date),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.count,
    required this.money,
  });
  final double total;
  final int count;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Resumen ($count servicios)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                money.format(total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'El precio mostrado es referencial. La cita se confirma en sucursal.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.result});
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final time = (result['time'] as String?) ?? '--:--';
    final date = (result['date'] as String?) ?? '';
    final estimated = (result['estimatedMin'] as num?)?.toInt() ?? 0;
    final saturation = (result['saturation'] as String?) ?? 'medio';
    final reason = (result['reason'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Cita confirmada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$date · $time hrs',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tiempo estimado: ~$estimated min · Saturacion $saturation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              reason,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreparationsRecap extends ConsumerWidget {
  const _PreparationsRecap({required this.idsEstudio});
  final List<int> idsEstudio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tips = <(String, String)>[];
    for (final id in idsEstudio) {
      final cat = ref.read(categoryByIdProvider(id));
      if (cat != null) tips.add((cat.nombre, cat.preparacion));
    }
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Como prepararte'),
        const SizedBox(height: 8),
        ...tips.map(
          (t) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFB45309).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFFB45309)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capitalizeWords(t.$1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.$2,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu carrito esta vacio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige al menos un servicio del catalogo para agendar.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go('/services'),
              icon: const Icon(Icons.medical_services),
              label: const Text('Ver catalogo'),
            ),
          ],
        ),
      ),
    );
  }
}
