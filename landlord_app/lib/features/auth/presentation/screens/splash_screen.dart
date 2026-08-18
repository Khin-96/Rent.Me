import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isFadingOut = false;

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final startedAt = DateTime.now();
    try {
      await ref
          .read(authProvider.notifier)
          .checkAuth()
          .timeout(const Duration(milliseconds: 700));
    } catch (_) {
      ref.read(authProvider.notifier).finishLoading();
    }

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = const Duration(milliseconds: 950) - elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);
    if (!mounted) return;

    setState(() => _isFadingOut = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final user = ref.read(authProvider).user;
    if (user != null && (user.role == 'LANDLORD' || user.role == 'ADMIN')) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isFadingOut ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      child: Scaffold(
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
                  child: Icon(Icons.apartment_rounded,
                      color: AppColors.primary, size: 38),
                ),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.6, 0.6),
                      duration: 600.ms,
                      curve: Curves.easeOutBack)
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
                  .slideY(begin: 0.3, duration: 500.ms)
                  .fadeIn(),
              const SizedBox(height: 8),
              Text(
                'Landlord & Caretaker Portal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withOpacity(0.6),
                    ),
              )
                  .animate(delay: 500.ms)
                  .slideY(begin: 0.3, duration: 500.ms)
                  .fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
