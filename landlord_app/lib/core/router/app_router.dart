import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/messaging/presentation/screens/landlord_messages_screen.dart';
import '../../features/messaging/presentation/screens/landlord_thread_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/properties/presentation/screens/add_property_wizard.dart';
import '../../features/properties/presentation/screens/dashboard_screen.dart';
import '../../features/properties/presentation/screens/edit_property_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.user != null;
      final isLandlordOrAdmin =
          authState.user?.role == 'LANDLORD' || authState.user?.role == 'ADMIN';

      final onSplash = state.matchedLocation == '/splash';
      final onAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (onSplash) return null;

      if (!isLoggedIn && !onAuth) return '/login';
      if (isLoggedIn && !isLandlordOrAdmin && !onAuth) return '/login';
      if (isLoggedIn && isLandlordOrAdmin && onAuth) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const MaterialPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            const MaterialPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: DashboardScreen()),
      ),
      GoRoute(
        path: '/add',
        pageBuilder: (context, state) =>
            const MaterialPage(child: AddPropertyWizard()),
      ),
      GoRoute(
        path: '/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(child: EditPropertyScreen(propertyId: id));
        },
      ),
      GoRoute(
        path: '/messages',
        pageBuilder: (context, state) =>
            const MaterialPage(child: LandlordMessagesScreen()),
      ),
      GoRoute(
        path: '/messages/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final propertyId = state.uri.queryParameters['propertyId'];
          final name = state.uri.queryParameters['name'];
          return MaterialPage(
            child: LandlordThreadScreen(
              otherUserId: userId,
              propertyId: propertyId?.isEmpty == true ? null : propertyId,
              otherUserName: name,
            ),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            const MaterialPage(child: ProfileScreen()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) =>
            const MaterialPage(child: AdminDashboardScreen()),
      ),
    ],
  );
});
