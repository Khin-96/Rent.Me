import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../properties/presentation/widgets/property_card.dart';
import 'providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final savedProperties = favoritesState.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(favoritesProvider.notifier).fetchFavorites();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (favoritesState.isLoading && savedProperties.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (savedProperties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.gray400),
                  const SizedBox(height: 16),
                  Text(
                    'No saved properties',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Your saved homes will appear here.', style: TextStyle(color: AppColors.gray500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedProperties.length,
            itemBuilder: (context, index) {
              final property = savedProperties[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(
                  property: property,
                  onTap: () {
                    context.push('/property/${property.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
