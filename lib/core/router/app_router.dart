import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/pages/request_service_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/branches/presentation/pages/branch_recommendation_page.dart';
import '../../features/checkin/presentation/pages/clinical_validation_page.dart';
import '../../features/checkin/presentation/pages/qr_pass_page.dart';
import '../../features/services/presentation/providers/catalog_providers.dart';
import '../../features/clinic_map/presentation/pages/clinic_map_page.dart';
import '../../features/home/presentation/pages/home_dashboard_page.dart';
import '../../features/home/presentation/pages/home_shell.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/results/presentation/pages/results_list_page.dart';
import '../../features/services/presentation/pages/service_cart_page.dart';
import '../../features/services/presentation/pages/services_categories_page.dart';
import '../../features/services/presentation/pages/services_list_page.dart';
import '../../features/studies/presentation/pages/preparations_page.dart';
import '../../features/studies/presentation/pages/studies_order_page.dart';
import '../../features/survey/presentation/pages/satisfaction_survey_page.dart';
import '../../features/tracking/presentation/pages/tracking_page.dart';
import '../../features/waiting/presentation/pages/live_waiting_page.dart';

final _rootKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  // Si el estado de auth cambia, el router refresca y aplica el redirect.
  ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final loggedIn =
          ref.read(authControllerProvider).valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),

      // Shell con bottom nav
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/studies',
                builder: (_, __) => const StudiesOrderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/results',
                builder: (_, __) => const ResultsListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // Rutas que se abren por encima del shell (push)
      GoRoute(
        path: '/branches',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final selecting = state.uri.queryParameters['selecting'] == '1';
          final idEstudio =
              int.tryParse(state.uri.queryParameters['id_estudio'] ?? '') ?? 2;
          return BranchRecommendationPage(
            idEstudio: idEstudio,
            selecting: selecting,
          );
        },
      ),
      GoRoute(
        path: '/request-service',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RequestServicePage(),
      ),
      GoRoute(
        path: '/waiting',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const LiveWaitingPage(),
      ),
      GoRoute(
        path: '/preparations',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PreparationsPage(),
      ),
      // Pase QR de la cita activa (sin params — usa la ultima reservacion).
      GoRoute(
        path: '/checkin',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const QrPassPage(branchId: CoyoacanBranch.id),
      ),
      GoRoute(
        path: '/checkin/:branchId',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => QrPassPage(
          branchId: int.parse(state.pathParameters['branchId']!),
        ),
      ),
      GoRoute(
        path: '/clinical-validation',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ClinicalValidationPage(),
      ),
      GoRoute(
        path: '/clinic-map',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final studyId =
              state.uri.queryParameters['studyId'];
          return ClinicMapPage(studyId: studyId);
        },
      ),
      GoRoute(
        path: '/services',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ServicesCategoriesPage(),
      ),
      GoRoute(
        path: '/services/cart',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ServiceCartPage(),
      ),
      GoRoute(
        path: '/services/:idEstudio',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ServicesListPage(
          idEstudio: int.parse(state.pathParameters['idEstudio']!),
        ),
      ),
      GoRoute(
        path: '/tracking',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const TrackingPage(),
      ),
      GoRoute(
        path: '/survey',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SatisfactionSurveyPage(),
      ),
    ],
  );
});

/// Adaptador entre Riverpod y `Listenable` para `refreshListenable` de GoRouter.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
