import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/salud_digna_catalog.dart';
import '../providers/catalog_providers.dart';
import 'services_categories_page.dart' show iconForCategory, capitalizeWords;

/// Lista de variantes de una categoria del catalogo local.
/// Permite buscar, ver detalle/preparacion y agregar al carrito.
class ServicesListPage extends ConsumerStatefulWidget {
  const ServicesListPage({super.key, required this.idEstudio});

  final int idEstudio;

  @override
  ConsumerState<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends ConsumerState<ServicesListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // Asegura que el catalogo del backend este cargado antes de buscar
    // la categoria por id (si entras directo desde un deeplink).
    final remoteAsync = ref.watch(remoteCatalogProvider);
    final category = ref.watch(categoryByIdProvider(widget.idEstudio));
    final cart = ref.watch(serviceCartProvider);

    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Servicios')),
        body: Center(
          child: remoteAsync.isLoading
              ? const CircularProgressIndicator()
              : const Text('Categoria no encontrada'),
        ),
      );
    }

    final items = category.items.where((s) {
      if (_query.isEmpty) return true;
      return s.nombre.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(capitalizeWords(category.nombre)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          _CategoryHeader(category: category),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar servicio...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
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
                Text(
                  '${items.length} servicios',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (cart.totalItems > 0)
                  Text(
                    'Carrito: ${cart.totalItems}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ServiceCard(
                      item: items[i],
                      category: category,
                      isInCart: cart.contains(items[i].id),
                      onTap: () => _showDetail(items[i], category),
                      onAdd: () => ref
                          .read(serviceCartProvider.notifier)
                          .toggle(items[i]),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cart.totalItems == 0
          ? null
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: () => context.push('/services/cart'),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(
                    'Continuar (${cart.totalItems}) · '
                    '\$${cart.total.toStringAsFixed(0)} MXN',
                  ),
                ),
              ),
            ),
    );
  }

  void _showDetail(CatalogItem s, CatalogCategory cat) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ServiceDetailSheet(item: s, category: cat),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final CatalogCategory category;

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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconForCategory(category.icono),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  capitalizeWords(category.nombre),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            category.descripcion,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Pill(
                label: '${category.items.length} servicios',
                icon: Icons.list_alt,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: '~${category.tiempoEsperaVigenteMin} min espera',
                icon: Icons.schedule,
              ),
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
  const _ServiceCard({
    required this.item,
    required this.category,
    required this.isInCart,
    required this.onTap,
    required this.onAdd,
  });

  final CatalogItem item;
  final CatalogCategory category;
  final bool isInCart;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );
    final isPaquete = item.nombre.toLowerCase().contains('paquete');

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
              color: isInCart
                  ? AppColors.primary
                  : (isPaquete ? AppColors.primary : AppColors.border),
              width: isInCart || isPaquete ? 1.6 : 1,
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
                      capitalizeWords(item.nombre),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
              // Badges en su propia fila con Wrap — soporta nombres largos
              // sin generar overflow horizontal.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (isPaquete)
                    const _Badge(
                      label: 'Paquete',
                      icon: Icons.inventory_2,
                      color: AppColors.primary,
                      bg: AppColors.primarySoft,
                    ),
                  _Badge(
                    label: '~${category.tiempoEsperaVigenteMin} min',
                    icon: Icons.schedule,
                    color: const Color(0xFF4338CA),
                    bg: const Color(0xFFEEF2FF),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Boton de agregar al carrito ocupa el ancho completo.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: Icon(
                    isInCart ? Icons.check : Icons.add_shopping_cart,
                    size: 18,
                  ),
                  label: Text(isInCart ? 'En carrito' : 'Agregar'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isInCart ? AppColors.success : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
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

class _ServiceDetailSheet extends ConsumerWidget {
  const _ServiceDetailSheet({required this.item, required this.category});
  final CatalogItem item;
  final CatalogCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );
    final cart = ref.watch(serviceCartProvider);
    final isInCart = cart.contains(item.id);
    final isPaquete = item.nombre.toLowerCase().contains('paquete');

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
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
            if (isPaquete)
              const _Badge(
                label: 'Paquete',
                icon: Icons.inventory_2,
                color: AppColors.primary,
                bg: AppColors.primarySoft,
              ),
            const SizedBox(height: 10),
            Text(
              capitalizeWords(item.nombre),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              capitalizeWords(category.nombre),
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
                    const Icon(Icons.local_offer, color: AppColors.primary),
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
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.schedule,
              title: 'Tiempo aproximado',
              detail:
                  '~${category.tiempoEsperaVigenteMin} min de espera + '
                  '${category.tiempoServicioMin} min de atencion',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on,
              title: 'Sucursal',
              detail: 'Coyoacan · Av. Universidad 1330',
            ),
            const SizedBox(height: 16),
            _PreparationBlock(category: category),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                ref.read(serviceCartProvider.notifier).toggle(item);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isInCart
                          ? 'Quitado de tu carrito'
                          : 'Agregado a tu carrito',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: Icon(
                isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
              ),
              label: Text(isInCart ? 'Quitar del carrito' : 'Agregar al carrito'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: isInCart ? AppColors.danger : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _PreparationBlock extends StatelessWidget {
  const _PreparationBlock({required this.category});
  final CatalogCategory category;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFB45309);
    const bg = Color(0xFFFEF3C7);

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
          const Icon(Icons.tips_and_updates, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Como prepararte',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.preparacion,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
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
