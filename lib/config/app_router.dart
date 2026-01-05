import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../blocs/authentication/authentication_bloc.dart';
import '../blocs/authentication/authentication_state.dart';
import '../pages/login_page.dart';
import '../pages/main_navigation_page.dart';
import '../pages/splash_page.dart';
import '../pages/profile_page.dart';
import 'app_routes.dart';

class AppRouter {
  static GoRouter router(AuthenticationBloc authenticationBloc) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: GoRouterRefreshStream(authenticationBloc.stream),
      redirect: (context, state) {
        final authState = authenticationBloc.state;
        final isOnSplash = state.matchedLocation == AppRoutes.splash;
        final isOnLogin = state.matchedLocation == AppRoutes.login;

        // Handle authentication states
        switch (authState.status) {
          case AuthenticationStatus.unknown:
            // Show splash while determining auth status
            return isOnSplash ? null : AppRoutes.splash;
          
          case AuthenticationStatus.unauthenticated:
            // Redirect to login if not authenticated
            return isOnLogin ? null : AppRoutes.login;
          
          case AuthenticationStatus.authenticated:
            // Redirect to home if authenticated and on login/splash
            if (isOnLogin || isOnSplash) {
              return AppRoutes.home;
            }
            // Allow access to authenticated routes
            return null;
        }
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splashName,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.loginName,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          builder: (context, state) => const MainNavigationPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profileName,
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    );
  }
}

/// A GoRouter refresh stream that listens to authentication changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthenticationState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (AuthenticationState state) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthenticationState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}