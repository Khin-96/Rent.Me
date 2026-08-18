import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../properties/data/property_model.dart';

class FavoritesState {
  final List<PropertyModel> favorites;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<PropertyModel>? favorites,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const FavoritesState()) {
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/favorites');

      if (response.statusCode == 200) {
        final list = response.data as List;
        final favorites = list.map((item) => PropertyModel.fromJson(item)).toList();
        state = FavoritesState(favorites: favorites, isLoading: false);
      }
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Failed to load favorites';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
    }
  }

  Future<bool> toggleFavorite(PropertyModel property) async {
    final isFav = isFavorited(property.id);
    
    // Optimistic UI updates
    final updatedList = List<PropertyModel>.from(state.favorites);
    if (isFav) {
      updatedList.removeWhere((p) => p.id == property.id);
    } else {
      updatedList.add(property);
    }
    state = state.copyWith(favorites: updatedList);

    try {
      final dio = _ref.read(dioProvider);
      if (isFav) {
        await dio.delete('/favorites/${property.id}');
      } else {
        await dio.post('/favorites/${property.id}');
      }
      return true;
    } on DioException catch (e) {
      // Revert optimistic update on failure
      fetchFavorites();
      return false;
    } catch (e) {
      fetchFavorites();
      return false;
    }
  }

  bool isFavorited(String propertyId) {
    return state.favorites.any((p) => p.id == propertyId);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier(ref);
});
