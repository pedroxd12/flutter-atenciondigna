import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../services/data/salud_digna_catalog.dart';
import '../../../services/presentation/pages/services_categories_page.dart'
    show iconForCategory, capitalizeWords;
import '../../../services/presentation/providers/catalog_providers.dart';
import '../../../studies/presentation/providers/studies_providers.dart';
import '../../../waiting/presentation/providers/waiting_providers.dart';

/// Pantalla "Inicio" — punto de entrada del paciente.
///
/// Distribucion (de arriba hacia abajo):
///   1. Saludo + perfil
///   2. Sucursal Coyoacan (siempre visible — MVP)
///   3. Cita activa (si existe) o tarjeta vacia
///   4. Tarjeta destacada de paquetes/promociones
///   5. Categorias rapidas (12 categorias del Excel)
///   6. Acceso al carrito (si tiene servicios seleccionados)
///   7. Estado en vivo de la espera (cuando aplica)
class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(authControllerProvider).valueOrNull;
    final studiesAsync = ref.watch(todaysStudiesProvider);
    final waitAsync = ref.watch(waitStatusStreamProvider);
    // Dispara la carga del catalogo desde el backend para que cuando el
    // usuario entre a "Servicios" ya este disponible. El localCatalogProvider
    // siempre devuelve algo (fallback hardcodeado si la red falla).
    ref.watch(remoteCatalogProvider);
    final catalog = ref.watch(localCatalogProvider);
    final cart = ref.watch(serviceCartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // 1. Saludo
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hola',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        patient?.firstName ?? 'paciente',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Sucursal fija (Coyoacan)
            const _BranchBanner(),
            const SizedBox(height: 18),

            // 3. Cita activa
            studiesAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => const _NoAppointmentCard(),
              data: (studies) {
                if (studies.isEmpty) return const _NoAppointmentCard();
                final main = studies.first;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Tu cita',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'PROXIMA',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          main.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          main.area,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () => context.push('/checkin'),
                          child: const Text('Ver mi cita'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            // 4. Paquetes destacados
            const Row(
              children: [
                Text(
                  'Paquetes destacados',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _featuredPackages(catalog)
                    .map(
                      (p) => _PackageCard(
                        title: p.$1,
                        category: p.$2,
                        price: p.$3,
                        onTap: () => context.push('/services/${p.$4}'),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 18),

            // 5. Categorias rapidas
            const Text(
              'Servicios por categoria',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
              children: catalog
                  .map((c) => _MiniCategory(category: c))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => context.push('/services'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver catalogo completo'),
              ),
            ),

            // 6. Carrito si hay items
            if (cart.totalItems > 0) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.push('/services/cart'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cart.totalItems} servicios en tu carrito',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Total: \$${cart.total.toStringAsFixed(0)} MXN — toca para agendar',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],

            // 7. Estado en vivo de la espera
            waitAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (status) {
                if (status.peopleAhead == 0 && !status.isYourTurn) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: GestureDetector(
                    onTap: () => context.push('/waiting'),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.isYourTurn
                                      ? 'Es tu turno'
                                      : '${status.peopleAhead} personas adelante',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Toca para ver tu turno',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Selecciona 4 items destacados para mostrar en el carrusel del home.
  /// Toma el primer "paquete" de cada categoria que tenga, y si no, el primero.
  List<(String, String, double?, int)> _featuredPackages(
    List<CatalogCategory> cats,
  ) {
    final out = <(String, String, double?, int)>[];
    final preferOrder = [2, 3, 6, 5]; // LAB, MASTOGRAFIA, ULTRASONIDO, RAYOS X
    for (final id in preferOrder) {
      CatalogCategory? cat;
      for (final c in cats) {
        if (c.idEstudio == id) {
          cat = c;
          break;
        }
      }
      if (cat == null || cat.items.isEmpty) continue;
      CatalogItem? paquete;
      for (final i in cat.items) {
        if (i.nombre.toLowerCase().contains('paquete')) {
          paquete = i;
          break;
        }
      }
      paquete ??= cat.items.first;
      out.add((paquete.nombre, cat.nombre, paquete.precio, cat.idEstudio));
    }
    return out;
  }
}

class _BranchBanner extends StatelessWidget {
  const _BranchBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sucursal Coyoacan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Av. Universidad 1330 · 7:00 - 20:00',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    required this.category,
    required this.price,
    required this.onTap,
  });
  final String title;
  final String category;
  final double? price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                capitalizeWords(category),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                capitalizeWords(title),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            if (price != null)
              Text(
                money.format(price),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniCategory extends StatelessWidget {
  const _MiniCategory({required this.category});
  final CatalogCategory category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/services/${category.idEstudio}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconForCategory(category.icono),
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              capitalizeWords(category.nombre),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Card(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _NoAppointmentCard extends StatelessWidget {
  const _NoAppointmentCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.event_available, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'No tienes citas programadas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Elige los servicios que necesitas y agendamos por ti.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => GoRouter.of(context).push('/services'),
              icon: const Icon(Icons.add_circle),
              label: const Text('Ver servicios'),
            ),
          ],
        ),
      ),
    );
  }
}
