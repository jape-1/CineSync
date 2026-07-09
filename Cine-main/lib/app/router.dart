import 'package:go_router/go_router.dart';

import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/auth_cubit.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/seat_selection_screen.dart';
import '../screens/snacks_screen.dart';
import '../screens/confirmation_screen.dart';
import '../screens/ticket_screen.dart';
import '../screens/my_tickets_screen.dart';
import '../features/staff/domain/models.dart';
import '../features/staff/presentation/worker_home_screen.dart';
import '../features/staff/presentation/scanner_screen.dart';
import '../screens/validation_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/peliculas_admin_screen.dart';
import '../features/admin/presentation/salas_admin_screen.dart';
import '../features/admin/presentation/funciones_admin_screen.dart';
import '../features/admin/presentation/dulceria_admin_screen.dart';
import '../features/admin/presentation/promociones_admin_screen.dart';
import '../features/admin/presentation/usuarios_admin_screen.dart';
import '../features/admin/presentation/reportes_admin_screen.dart';

/// Ruta de aterrizaje según el rol del usuario autenticado.
String homePathForRole(UserRole rol) {
  switch (rol) {
    case UserRole.cliente:
      return '/home';
    case UserRole.trabajador:
      return '/worker';
    case UserRole.administrador:
      return '/admin';
  }
}

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final auth = authCubit.state;
      final loc = state.matchedLocation;
      final onAuthScreen = loc == '/login' || loc == '/register';
      final onSplash = loc == '/splash';

      // Aún resolviendo la sesión → quedarse en el splash.
      if (auth.status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }

      // No autenticado → al login (salvo que ya esté en login/registro).
      if (auth.status == AuthStatus.unauthenticated) {
        return onAuthScreen ? null : '/login';
      }

      // Autenticado.
      final home = homePathForRole(auth.user!.rol);
      if (onAuthScreen || onSplash) return home;

      // Guarda por rol: cada área solo la ve su rol.
      final rol = auth.user!.rol;
      if (loc.startsWith('/worker') && rol != UserRole.trabajador && rol != UserRole.administrador) {
        return home;
      }
      if (loc.startsWith('/admin') && rol != UserRole.administrador) {
        return home;
      }
      final clientArea = ['/home', '/movie', '/seats', '/snacks', '/confirmation', '/ticket', '/my-tickets'];
      if (clientArea.any(loc.startsWith) && rol != UserRole.cliente) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // --- Cliente ---
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/movie/:id',
        builder: (_, s) =>
            MovieDetailScreen(peliculaId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/seats/:funcionId',
        builder: (_, s) => SeatSelectionScreen(
          funcionId: int.parse(s.pathParameters['funcionId']!),
        ),
      ),
      GoRoute(path: '/snacks', builder: (_, __) => const SnacksScreen()),
      GoRoute(path: '/confirmation', builder: (_, __) => const ConfirmationScreen()),
      GoRoute(
        path: '/ticket/:compraId',
        builder: (_, s) =>
            TicketScreen(compraId: int.parse(s.pathParameters['compraId']!)),
      ),
      GoRoute(path: '/my-tickets', builder: (_, __) => const MyTicketsScreen()),

      // --- Trabajador ---
      GoRoute(path: '/worker', builder: (_, __) => const WorkerHomeScreen()),
      GoRoute(path: '/worker/scan', builder: (_, __) => const ScannerScreen()),
      GoRoute(
        path: '/worker/result',
        builder: (_, s) =>
            ValidationScreen(resultado: s.extra as ValidacionResponse?),
      ),

      // --- Administrador ---
      GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
      GoRoute(
          path: '/admin/peliculas',
          builder: (_, __) => const PeliculasAdminScreen()),
      GoRoute(
          path: '/admin/salas', builder: (_, __) => const SalasAdminScreen()),
      GoRoute(
          path: '/admin/funciones',
          builder: (_, __) => const FuncionesAdminScreen()),
      GoRoute(
          path: '/admin/dulceria',
          builder: (_, __) => const DulceriaAdminScreen()),
      GoRoute(
          path: '/admin/promociones',
          builder: (_, __) => const PromocionesAdminScreen()),
      GoRoute(
          path: '/admin/usuarios',
          builder: (_, __) => const UsuariosAdminScreen()),
      GoRoute(
          path: '/admin/reportes',
          builder: (_, __) => const ReportesAdminScreen()),
    ],
  );
}
