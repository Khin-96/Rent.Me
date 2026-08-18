import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').take(2).map((n) => n[0].toUpperCase()).join()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(initials,
                  style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            ).animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(user.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))
                .animate(delay: 100.ms)
                .slideY(begin: 0.2)
                .fadeIn(),
            const SizedBox(height: 4),
            Text(user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray500))
                .animate(delay: 150.ms)
                .slideY(begin: 0.2)
                .fadeIn(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role == 'ADMIN' ? 'Administrator' : 'Landlord',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 36),
            _SectionCard(
              children: [
                _Tile(icon: Icons.person_outline_rounded, label: 'Full name', value: user.name),
                _Tile(icon: Icons.email_outlined, label: 'Email', value: user.email),
                if (user.phone != null)
                  _Tile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone!),
              ],
            ).animate(delay: 250.ms).slideY(begin: 0.2).fadeIn(),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.home_work_outlined, size: 20),
                  title: const Text('My properties', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.gray400),
                  onTap: () => context.go('/'),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  title: const Text('Inbox', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.gray400),
                  onTap: () => context.go('/messages'),
                ),
                if (user.role == 'ADMIN')
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                    title: const Text('Admin dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.gray400),
                    onTap: () => context.push('/admin'),
                  ),
              ],
            ).animate(delay: 300.ms).slideY(begin: 0.2).fadeIn(),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                  title: const Text('Sign out',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ).animate(delay: 350.ms).slideY(begin: 0.2).fadeIn(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Tile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.gray500),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400)),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
