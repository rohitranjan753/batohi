import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/authentication/authentication_bloc.dart';
import '../blocs/authentication/authentication_state.dart';
import '../blocs/itinerary/itinerary_bloc.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/stay/stay_bloc.dart';
import '../blocs/mytrips/mytrips_bloc.dart';
import '../models/trip.dart';
import '../pages/login_page.dart';
import '../pages/main_navigation_page.dart';
import '../pages/splash_page.dart';
import '../pages/profile_page.dart';
import '../pages/trip_detail_page.dart';
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
        GoRoute(
          path: '/trip/:tripId',
          name: AppRoutes.tripDetailName,
          builder: (context, state) {
            final tripId = state.pathParameters['tripId']!;
            // Get the trip from MyTripsBloc
            final myTripsState = context.read<MyTripsBloc>().state;
            final trip = myTripsState.trips.firstWhere(
              (t) => t.id == tripId,
              orElse: () => Trip(
                id: tripId,
                tripName: 'Loading...',
                destination: '',
                startDate: DateTime.now(),
                endDate: DateTime.now(),
                budget: 0,
                userId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ItineraryBloc()),
                BlocProvider(create: (_) => ExpenseBloc()),
                BlocProvider(create: (_) => StayBloc()),
              ],
              child: TripDetailPage(trip: trip),
            );
          },
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