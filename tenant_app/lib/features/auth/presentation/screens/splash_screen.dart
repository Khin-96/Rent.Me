import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/shared_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Check authentication
    try {
      await ref
          .read(authProvider.notifier)
          .checkAuth()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      ref.read(authProvider.notifier).finishLoading();
    }

    if (!mounted) return;
    final user = ref.read(authProvider).user;
    if (user != null && user.role == 'TENANT') {
      final prefs = ref.read(sharedPreferencesProvider);
      final surveyCompleted = prefs.getBool('survey_completed_v1') ?? false;
      if (!surveyCompleted) {
        context.go('/survey');
      } else {
        context.go('/');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            Text(
              'Rent.ME',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            )
                .animate(delay: 300.ms)
                .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Find your next home',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withOpacity(0.6),
                  ),
            )
                .animate(delay: 500.ms)
                .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
