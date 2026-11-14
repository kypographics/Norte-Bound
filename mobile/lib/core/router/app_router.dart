import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;


import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/discovery/domain/destination_summary.dart';
import '../../features/discovery/presentation/screens/destination_detail_screen.dart';
import '../../features/discovery/presentation/screens/discovery_screen.dart';
import '../../features/discovery/presentation/screens/search_screen.dart';
import '../../features/preferences/presentation/planner_screen.dart';
import '../../shared/widgets/app_shell_scaffold.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _discoveryNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'discovery',
);
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _plannerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'planner');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    restorationScopeId: 'norte-bound',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.destinationDetailPath,
        name: AppRoutes.destinationDetailName,
        builder: (context, state) {
          final destination = state.extra;

          return DestinationDetailScreen(
            slug: state.pathParameters['slug'] ?? '',
            destination: destination is DestinationSummary ? destination : null,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _discoveryNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.discovery,
                name: AppRoutes.discoveryName,
                builder: (context, state) => const DiscoveryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: AppRoutes.searchName,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _plannerNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.planner,
                name: AppRoutes.plannerName,
                builder: (context, state) => const PlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});

String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authNotifierProvider);
  final location = state.matchedLocation;
  final isSplash = location == AppRoutes.splash;
  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;

  if (auth.isLoading) {
    return isSplash ? null : AppRoutes.splash;
  }

  if (auth.value == null) {
    if (isSplash) {
      return AppRoutes.login;
    }

    return isAuthRoute ? null : AppRoutes.login;
  }

  if (isSplash || isAuthRoute) {
    return AppRoutes.discovery;
  }

  return null;
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) {
      final previousUser = previous?.value;
      final nextUser = next.value;
      final identityChanged =
          previousUser?.id != nextUser?.id ||
          previousUser?.role != nextUser?.role;

      if (previous?.isLoading != next.isLoading || identityChanged) {
        notifyListeners();
      }
    });
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.skyBlueWash,
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    child: const Icon(
                      CupertinoIcons.compass,
                      color: AppColors.deepForest,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'This trail ends here.',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error?.toString() ??
                        'The page you are looking for does not exist.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForest,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.discovery),
                    icon: const Icon(CupertinoIcons.compass, size: 18),
                    label: const Text('Back to discovery'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
