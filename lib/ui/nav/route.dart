import 'package:go_router/go_router.dart';

import '../error.dart';
import '../screens/end_point_screen.dart';
import '../screens/first_run_screen.dart';
import '../screens/forgotten_password_screen.dart';
import '../screens/garden_bed_screen.dart';
import '../screens/history_screen.dart';
import '../screens/lighting_view_screen.dart';
import '../screens/login_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/schedule_screen.dart';
import 'home_with_drawer.dart';

bool userIsLoggedIn = true; // Global or stored in a Provider/Bloc, etc.
bool systemConfigured = true;

GoRouter get router => GoRouter(
      debugLogDiagnostics: true,
      // 1) Redirect root to either the first-run wizard, or if configured, then either /jobs if logged in or /login if not
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) {
            if (!systemConfigured) {
              return '/public/first_run';
            } else if (!userIsLoggedIn) {
              return '/overview';
            } else {
              return '/overview';
            }
          },
        ),
        // 2) A general error route
        GoRoute(
          path: '/error',
          builder: (context, state) {
            final message = state.extra as String? ?? 'Unknown Error';
            return ErrorScreen(errorMessage: message);
          },
        ),
        // 3) Public routes: The 'public' prefix is optional, but clarifies that these do NOT require auth
        GoRoute(
          path: '/public/login',
          builder: (context, state) =>
              const HomeWithDrawer(initialScreen: LoginScreen()),
        ),
        GoRoute(
          path: '/public/forgot_password',
          builder: (context, state) =>
              const HomeWithDrawer(initialScreen: ForgottenPasswordScreen()),
        ),
        GoRoute(
          path: '/public/reset_password',
          builder: (context, state) =>
              const HomeWithDrawer(initialScreen: ResetPasswordScreen()),
        ),
        GoRoute(
          path: '/public/first_run',
          builder: (context, state) =>
              const HomeWithDrawer(initialScreen: FirstRunScreen()),
        ),
        // 4) Authenticated (Private) routes. Each references a screen with a drawer + your main content
        GoRoute(
          path: '/lighting',
          builder: (_, __) =>
              const HomeWithDrawer(initialScreen: LightingViewScreen()),
        ),
        GoRoute(
          path: '/overview',
          builder: (_, __) =>
              const HomeWithDrawer(initialScreen: OverviewScreen()),
        ),
        GoRoute(
          path: '/schedule',
          builder: (_, __) =>
              const HomeWithDrawer(initialScreen: ScheduleScreen()),
        ),
        GoRoute(
          path: '/history',
          builder: (_, __) =>
              const HomeWithDrawer(initialScreen: HistoryScreen()),
        ),
        GoRoute(
          path: '/config/gardenbeds',
          builder: (_, __) => const HomeWithDrawer(
              initialScreen: GardenBedConfigurationScreen()),
        ),
        GoRoute(
          path: '/config/endpoints',
          builder: (_, __) => const HomeWithDrawer(
              initialScreen: EndPointConfigurationScreen()),
        ),
        // Add more private routes as needed...
      ],
      // 5) A routing guard or refresh logic can go here if you want to dynamically check [userIsLoggedIn] on each route
      redirect: (context, state) {
        // If system not configured => route them to /public/first_run
        if (!systemConfigured && state.uri.toString() != '/public/first_run') {
          return '/public/first_run';
        }
        // If user not logged in => route them to /public/login
        final isPublicRoute = state.uri.toString().startsWith('/public');
        if (!userIsLoggedIn && !isPublicRoute) {
          return '/public/login';
        }
        return null; // no change
      },
    );
