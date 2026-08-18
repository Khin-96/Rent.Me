import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/property_model.dart';
import '../providers/properties_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesState = ref.watch(propertiesProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Properties',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('${propertiesState.properties.length} listings',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.gray400)),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin panel',
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Add property',
            style:
                TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
      body: propertiesState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : propertiesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 40, color: AppColors.gray300),
                      const SizedBox(height: 12),
                      Text(propertiesState.error!,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                          onPressed: () => ref
                              .read(propertiesProvider.notifier)
                              .fetchMyProperties(),
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : propertiesState.properties.isEmpty
                  ? _EmptyState(onAdd: () => context.push('/add'))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref
                          .read(propertiesProvider.notifier)
                          .fetchMyProperties(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: propertiesState.properties.length,
                        itemBuilder: (context, index) {
                          final property = propertiesState.properties[index];
                          return _PropertyCard(property: property)
                              .animate(
                                  delay: Duration(milliseconds: index * 60))
                              .slideY(
                                  begin: 0.15,
                                  duration: 350.ms,
                                  curve: Curves.easeOut)
                              .fadeIn();
                        },
                      ),
                    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.home_work_outlined,
                  size: 36, color: AppColors.gray400),
            ),
            const SizedBox(height: 20),
            Text('No properties yet',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Add your first property to start receiving inquiries.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.gray400)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add property'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  final PropertyModel property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = property.status == 'AVAILABLE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  property.images.isNotEmpty
                      ? property.images.first
                      : 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.gray100,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.gray300, size: 32),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.gray400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(isActive ? 'ACTIVE' : 'PAUSED',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.gray400),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(property.address,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.gray400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(Formatters.currency(property.price),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Switch.adaptive(
                      value: isActive,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        final newStatus = value ? 'AVAILABLE' : 'PAUSED';
                        ref
                            .read(propertiesProvider.notifier)
                            .toggleStatus(property.id, newStatus);
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/edit/${property.id}'),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_outlined, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _confirmDelete(
                              context, ref, property.id, property.title),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(
              spacing: 8,
              children: [
                if (property.bedrooms != null)
                  _Chip(
                      icon: Icons.bed_outlined,
                      label: '${property.bedrooms} bed'),
                if (property.bathrooms != null)
                  _Chip(
                      icon: Icons.bathtub_outlined,
                      label: '${property.bathrooms} bath'),
                _Chip(
                    icon: Icons.home_outlined,
                    label: AppConstants.propertyTypeLabels[property.type] ??
                        property.type),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete property'),
        content: Text(
            'Are you sure you want to delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(propertiesProvider.notifier).deleteProperty(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.gray100, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gray500),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.gray600)),
        ],
      ),
    );
  }
}
