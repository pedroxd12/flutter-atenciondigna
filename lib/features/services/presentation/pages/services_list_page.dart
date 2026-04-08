import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/service_item.dart';
import '../providers/services_providers.dart';

/// Lista de servicios para una categoria. Muestra paquetes, precio,
/// y un badge cuando el servicio requiere preparacion previa.
class ServicesListPage extends ConsumerStatefulWidget {
  const ServicesListPage({super.key, required this.idEstudio});

  final int idEstudio;

  @override
  ConsumerState<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends ConsumerState<ServicesListPage> {
  String _query = '';
  bool _onlyPaquetes = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(serviciosPorCategoriaProvider(widget.idEstudio));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Servicios'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          final categoria = items.isNotEmpty ? items.first.categoria : '';
          final filtered = items.where((s) {
            if (_onlyPaquetes && !s.esPaquete) return false;
            if (_query.isEmpty) return true;
            return s.nombre.toLowerCase().contains(_query.toLowerCase());
          }).toList();

          final paquetesCount = items.where((s) => s.esPaquete).length;

          return Column(
            children: [
              _CategoryHeader(
                nombre: _capitalize(categoria),
                total: items.length,
                paquetes: paquetesCount,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar servicio...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Solo paquetes'),
                      selected: _onlyPaquetes,
                      onSelected: (v) => setState(() => _onlyPaquetes = v),
                      selectedColor: AppColors.primarySoft,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _onlyPaquetes
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length} resultados',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ServiceCard(
                          item: filtered[i],
                          onTap: () => _showDetail(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetail(ServiceItem s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ServiceDetailSheet(item: s),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.nombre,
    required this.total,
    required this.paquetes,
  });

  final String nombre;
  final int total;
  final int paquetes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Pill(label: '$total servicios', icon: Icons.list_alt),
              const SizedBox(width: 8),
              _Pill(label: '$paquetes paquetes', icon: Icons.inventory_2),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, required this.onTap});

  final ServiceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.esPaquete ? AppColors.primary : AppColors.border,
              width: item.esPaquete ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (item.precio != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      money.format(item.precio),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (item.esPaquete)
                    const _Badge(
                      label: 'Paquete',
                      icon: Icons.inventory_2,
                      color: AppColors.primary,
                      bg: AppColors.primarySoft,
                    ),
                  if (item.requierePreparacion)
                    const _Badge(
                      label: 'Requiere preparacion',
                      icon: Icons.warning_amber_rounded,
                      color: Color(0xFFB45309),
                      bg: Color(0xFFFEF3C7),
                    )
                  else
                    const _Badge(
                      label: 'Sin preparacion',
                      icon: Icons.check_circle,
                      color: AppColors.success,
                      bg: Color(0xFFD1FAE5),
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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailSheet extends StatelessWidget {
  const _ServiceDetailSheet({required this.item});
  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (item.esPaquete)
              const _Badge(
                label: 'Paquete',
                icon: Icons.inventory_2,
                color: AppColors.primary,
                bg: AppColors.primarySoft,
              ),
            const SizedBox(height: 10),
            Text(
              item.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.categoria,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            if (item.precio != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Precio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      money.format(item.precio),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _PreparationBlock(item: item),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Listo. Continua la cita en "Solicitar estudio"',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Elegir este servicio'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparationBlock extends StatelessWidget {
  const _PreparationBlock({required this.item});
  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final requires = item.requierePreparacion;
    final color = requires ? const Color(0xFFB45309) : AppColors.success;
    final bg = requires ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5);
    final icon = requires ? Icons.warning_amber_rounded : Icons.check_circle;
    final title = requires
        ? 'Requiere preparacion previa'
        : 'No requiere preparacion previa';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (item.preparacion != null &&
                    item.preparacion!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.preparacion!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('Sin resultados'),
        ],
      ),
    );
  }
}
