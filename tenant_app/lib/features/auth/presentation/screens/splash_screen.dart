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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _barAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

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
      context.go(surveyCompleted ? '/' : '/survey');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background geometric accent — subtle diagonal lines
          Positioned(
            top: -size.height * 0.15,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
            ).animate().scale(
              begin: const Offset(0.5, 0.5),
              duration: 1200.ms,
              curve: Curves.easeOut,
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.03),
                  width: 1,
                ),
              ),
            ).animate(delay: 200.ms).scale(
              begin: const Offset(0.5, 0.5),
              duration: 1400.ms,
              curve: Curves.easeOut,
            ),
          ),

          // Core content — centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wordmark — geometric R in a rounded square
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      'R',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0A0A0A),
                        height: 1,
                        letterSpacing: -2,
                        fontFamily: Theme.of(context).textTheme.headlineLarge?.fontFamily,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Brand name
                const Text(
                  'Rent.ME',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.2,
                  ),
                )
                    .animate(delay: 300.ms)
                    .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Find your next home',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.2,
                  ),
                )
                    .animate(delay: 500.ms)
                    .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // Bottom loading bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _barAnimation,
              builder: (context, _) {
                return SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: _barAnimation.value,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 3,
                  ),
                );
              },
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
          ),

          // Version tag — bottom right
          Positioned(
            bottom: 24,
            right: 20,
            child: Text(
              'v1.0.2',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 0.5,
              ),
            ).animate(delay: 700.ms).fadeIn(),
          ),
        ],
      ),
    );
  }
}
