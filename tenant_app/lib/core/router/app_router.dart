// ignore: unused_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/properties/presentation/screens/home_screen.dart';
import '../../features/properties/presentation/screens/survey_screen.dart';
import '../../features/properties/presentation/screens/property_detail_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/messaging/presentation/screens/messages_screen.dart';
import '../../features/messaging/presentation/screens/thread_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/tenant_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/survey',
        builder: (context, state) => const SurveyScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => TenantShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final latStr = state.uri.queryParameters['lat'];
              final lngStr = state.uri.queryParameters['lng'];
              final propertyId = state.uri.queryParameters['id'] ?? state.uri.queryParameters['propertyId'];
              final lat = latStr != null ? double.tryParse(latStr) : null;
              final lng = lngStr != null ? double.tryParse(lngStr) : null;
              return HomeScreen(
                destinationLat: lat,
                destinationLng: lng,
                destinationPropertyId: propertyId,
              );
            },
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ThreadScreen(
                  inquiryId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) => PropertyDetailScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
