import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// Scaffold con BottomNavigationBar — orquesta las 4 secciones principales
/// usando StatefulShellRoute de go_router.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    _NavItem(Icons.science_outlined, Icons.science_rounded, 'Estudios'),
    _NavItem(Icons.access_time, Icons.access_time_filled, 'Espera'),
    _NavItem(Icons.folder_outlined, Icons.folder_rounded, 'Resultados'),
    _NavItem(Icons.person_outline, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        destinations: _items
            .map(
              (it) => NavigationDestination(
                icon: Icon(it.icon),
                selectedIcon: Icon(it.activeIcon, color: AppColors.primary),
                label: it.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
