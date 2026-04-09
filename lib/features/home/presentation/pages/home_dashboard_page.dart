import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/messages/patient_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/message_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../services/data/salud_digna_catalog.dart';
import '../../../services/presentation/pages/services_categories_page.dart'
    show iconForCategory, capitalizeWords;
import '../../../services/presentation/providers/catalog_providers.dart';
import '../../../studies/presentation/providers/studies_providers.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../waiting/presentation/providers/waiting_providers.dart';

/// Pantalla "Inicio" — punto de entrada del paciente.
///
/// Distribucion simplificada:
///   1. Saludo personalizado + subtitulo guia
///   2. Estado en vivo (si aplica) — lo mas importante arriba
///   3. Cita activa o tarjeta vacia
///   4. Tips contextuales segun estudios
///   5. Paquetes destacados (carrusel)
///   6. Categorias rapidas (max 8, grid de 4)
///   7. Carrito (si tiene items)
class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(authControllerProvider).valueOrNull;
    final studiesAsync = ref.watch(todaysStudiesProvider);
    final waitAsync = ref.watch(waitStatusStreamProvider);
    ref.watch(remoteCatalogProvider);
    final catalog = ref.watch(localCatalogProvider);
    final cart = ref.watch(serviceCartProvider);

    final nombre = patient?.firstName ?? 'paciente';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // ── 1. Saludo personalizado ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $nombre',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aqui puedes ver tu cita, tu turno y tus estudios.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 1b. Tracking banner (prioridad maxima si hay visita activa) ──
            Consumer(builder: (context, ref, _) {
              final trackingAsync = ref.watch(trackingStatusProvider);
              return trackingAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (status) {
                  if (status == null || !status.hasActiveVisit) {
                    return const SizedBox.shrink();
                  }
                  final current = status.currentStudy;
                  final isCalled = current?.isCalled ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: () => context.push('/tracking'),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCalled
                                ? [const Color(0xFF16A34A), const Color(0xFF0F7A3F)]
                                : [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCalled
                                        ? Icons.notifications_active
                                        : Icons.track_changes,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isCalled
                                            ? 'Es tu turno!'
                                            : 'Tu visita esta en curso',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        current != null
                                            ? '${current.name} · ${status.completedStudies}/${status.totalStudies} estudios'
                                            : '${status.completedStudies} de ${status.totalStudies} estudios',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: status.progressPercent / 100,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ver mi tracking en vivo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // ── 2. Estado en vivo de la espera (arriba, prioridad) ──
            waitAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (status) {
                if (status.peopleAhead == 0 && !status.isYourTurn) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
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
                                color:
                                    AppColors.primary.withValues(alpha: 0.25),
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
                                      ? 'Es tu turno!'
                                      : '${status.peopleAhead} personas antes que tu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: status.isYourTurn
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  status.isYourTurn
                                      ? 'Dirigete al area asignada'
                                      : 'Toca para ver tu turno en vivo',
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

            // ── 3. Cita activa ──
            studiesAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => const _NoAppointmentCard(),
              data: (studies) {
                if (studies.isEmpty) return const _NoAppointmentCard();
                final main = studies.first;
                final totalMin = studies.fold<double>(
                  0,
                  (acc, s) => acc + s.estimatedMinutes,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_available,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Tu proxima cita',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
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
                                  child: Text(
                                    '${studies.length} estudio${studies.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (studies.length > 1) ...[
                              const SizedBox(height: 4),
                              Text(
                                '+ ${studies.length - 1} estudio${studies.length - 1 > 1 ? 's' : ''} mas',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              '${main.area} · ~${totalMin.toStringAsFixed(0)} min en total',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => context.push('/checkin'),
                                icon: const Icon(Icons.qr_code_2, size: 20),
                                label: const Text('Ver mi pase de entrada'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── 4. Tips contextuales segun estudios ──
                    Builder(builder: (context) {
                      final tips =
                          PatientMessages.tipsForStudies(nombre, studies);
                      if (tips.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: MessageBanner(
                            message: PatientMessages.stayAlert(nombre),
                            icon: Icons.phone_android_rounded,
                            style: MessageBannerStyle.info,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TIPS PARA TU VISITA',
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
                        ),
                      );
                    }),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // ── 5. Paquetes destacados ──
            const Text(
              'Paquetes destacados',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige un paquete y agendamos por ti.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
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

            const SizedBox(height: 28),

            // ── 6. Categorias rapidas (max 8) ──
            const Text(
              'Servicios por categoria',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.75,
              children: catalog
                  .take(8)
                  .map((c) => _MiniCategory(category: c))
                  .toList(),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => context.push('/services'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver todos los servicios'),
              ),
            ),

            // ── 7. Carrito flotante ──
            if (cart.totalItems > 0) ...[
              const SizedBox(height: 16),
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
                              '${cart.totalItems} servicio${cart.totalItems > 1 ? 's' : ''} en tu carrito',
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
          ],
        ),
      ),
    );
  }

  /// Selecciona 4 items destacados para mostrar en el carrusel del home.
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
