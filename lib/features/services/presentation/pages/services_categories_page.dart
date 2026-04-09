import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/salud_digna_catalog.dart';
import '../providers/catalog_providers.dart';

/// Catalogo de servicios — 12 categorias clinicas con sus variantes,
/// alimentado desde el archivo local generado a partir del Excel
/// `documentos/servicios salud digna.xlsx`.
///
/// Antes leia del backend (404 cuando estaba caido). Ahora siempre
/// muestra la lista completa, permite seleccionar varios servicios y
/// avanzar al carrito para agendar en Coyoacan.
class ServicesCategoriesPage extends ConsumerWidget {
  const ServicesCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dispara el fetch al backend (12 categorias + variantes + tiempos vivos
    // del modelo IA). Mientras carga, el localCatalogProvider devuelve el
    // fallback hardcodeado para que la UI nunca quede vacia.
    final remoteAsync = ref.watch(remoteCatalogProvider);
    final cats = ref.watch(localCatalogProvider);
    final cart = ref.watch(serviceCartProvider);
    final isLoading = remoteAsync.isLoading && cats.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Servicios Salud Digna'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(remoteCatalogProvider.future),
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            const _BranchHeader(),
            const SizedBox(height: 16),
            const _Header(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'Categorias',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (remoteAsync.isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (remoteAsync.hasError)
              _ErrorBox(
                message: 'No pudimos cargar el catalogo desde el servidor.',
                detail: remoteAsync.error.toString(),
                onRetry: () => ref.invalidate(remoteCatalogProvider),
              )
            else if (cats.isEmpty)
              _ErrorBox(
                message: 'La base de datos no tiene servicios cargados.',
                detail:
                    'Ejecuta `npx prisma db seed` en el backend para sembrar el catalogo.',
                onRetry: () => ref.invalidate(remoteCatalogProvider),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
                children:
                    cats.map((c) => _CategoryCard(category: c)).toList(),
              ),
          ],
        ),
        ),
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
                    'Ver carrito (${cart.totalItems}) · '
                    '\$${cart.total.toStringAsFixed(0)} MXN',
                  ),
                ),
              ),
            ),
    );
  }
}

class _BranchHeader extends StatelessWidget {
  const _BranchHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primarySoft,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sucursal: Coyoacan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CoyoacanBranch.direccion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Horario ${CoyoacanBranch.horaApertura}:00 - '
                    '${CoyoacanBranch.horaCierre}:00',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catalogo de servicios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Elige paquetes y nosotros agendamos tu cita',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData iconForCategory(String key) {
  switch (key) {
    case 'science':
      return Icons.science;
    case 'female':
      return Icons.female;
    case 'medical_information':
      return Icons.medical_information;
    case 'pregnant_woman':
      return Icons.pregnant_woman;
    case 'monitor_heart':
      return Icons.monitor_heart;
    case 'biotech':
      return Icons.biotech;
    case 'auto_graph':
      return Icons.auto_graph;
    case 'restaurant':
      return Icons.restaurant;
    case 'favorite_border':
      return Icons.favorite_border;
    case 'accessibility_new':
      return Icons.accessibility_new;
    case 'visibility':
      return Icons.visibility;
    case 'medical_services':
    default:
      return Icons.medical_services;
  }
}

String capitalizeWords(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
    .join(' ');

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final CatalogCategory category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/services/${category.idEstudio}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconForCategory(category.icono),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  capitalizeWords(category.nombre),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.items.length} servicios',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (category.tiempoEsperaActualMin != null) ...[
                    const Icon(
                      Icons.bolt,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      '~${category.tiempoTotalVigenteMin} min',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: category.tiempoEsperaActualMin != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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


class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
