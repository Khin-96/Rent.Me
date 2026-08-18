import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/priority_queue.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../data/property_model.dart';

class PropertiesState {
  final List<PropertyModel> properties;
  final bool isLoading;
  final String? error;
  final PropertyModel? selectedProperty;
  final String searchQuery;
  final double? minRent;
  final double? maxRent;
  final String? selectedType;
  final List<String> selectedAmenities;

  const PropertiesState({
    this.properties = const [],
    this.isLoading = false,
    this.error,
    this.selectedProperty,
    this.searchQuery = '',
    this.minRent,
    this.maxRent,
    this.selectedType,
    this.selectedAmenities = const [],
  });

  PropertiesState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    String? error,
    PropertyModel? selectedProperty,
    String? searchQuery,
    double? minRent,
    double? maxRent,
    String? selectedType,
    List<String>? selectedAmenities,
  }) {
    return PropertiesState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedProperty: selectedProperty ?? this.selectedProperty,
      searchQuery: searchQuery ?? this.searchQuery,
      minRent: minRent ?? this.minRent,
      maxRent: maxRent ?? this.maxRent,
      selectedType: selectedType ?? this.selectedType,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
    );
  }
}

class PropertiesNotifier extends StateNotifier<PropertiesState> {
  final Ref _ref;

  PropertiesNotifier(this._ref) : super(const PropertiesState());

  Future<void> fetchProperties({
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = _ref.read(dioProvider);

      final params = <String, dynamic>{};
      if (state.minRent != null) params['minRent'] = state.minRent!.toInt();
      if (state.maxRent != null) params['maxRent'] = state.maxRent!.toInt();
      if (state.selectedType != null) params['type'] = state.selectedType;
      if (state.searchQuery.isNotEmpty) params['q'] = state.searchQuery;

      if (state.selectedAmenities.isNotEmpty) {
        params['amenities'] = state.selectedAmenities.join(',');
      }

      if (minLat != null &&
          maxLat != null &&
          minLng != null &&
          maxLng != null) {
        params['minLat'] = minLat;
        params['maxLat'] = maxLat;
        params['minLng'] = minLng;
        params['maxLng'] = maxLng;
      }

      final response = await dio.get('/properties', queryParameters: params);

      if (response.statusCode == 200) {
        final list = response.data as List;
        final rawProperties =
            list.map((item) => PropertyModel.fromJson(item)).toList();

        // Recommended Sorting via Priority Queue
        final prefs = _ref.read(sharedPreferencesProvider);
        final double? surveyMaxRent = prefs.getDouble('survey_max_rent');
        final List<String> surveyPreferredTypes =
            prefs.getStringList('survey_preferred_types') ?? [];
        final List<String> surveyMustHaveAmenities =
            prefs.getStringList('survey_must_have_amenities') ?? [];
        final double? userLat = prefs.getDouble('user_lat');
        final double? userLng = prefs.getDouble('user_lng');

        final pq = PriorityQueue<PropertyModel>();
        for (final item in rawProperties) {
          double score = 0.0;

          // Proximity Score (Max 50 points)
          if (userLat != null && userLng != null) {
            final dist = PriorityQueue.calculateDistance(
              userLat,
              userLng,
              item.latitude,
              item.longitude,
            );
            score += 50.0 * (1.0 / (dist + 1.0));
          }

          // Budget Score (Max 30 points)
          if (surveyMaxRent != null) {
            if (item.rentAmount <= surveyMaxRent) {
              score += 30.0;
            } else if (item.rentAmount <= surveyMaxRent * 1.15) {
              score += 15.0;
            }
          }

          // Preferred Types Score (Max 25 points)
          if (surveyPreferredTypes.isNotEmpty) {
            if (surveyPreferredTypes.contains(item.type)) {
              score += 25.0;
            }
          }

          // Must-have Amenities Score (10 points per match)
          if (surveyMustHaveAmenities.isNotEmpty) {
            for (final am in item.amenities) {
              if (surveyMustHaveAmenities.contains(am)) {
                score += 10.0;
              }
            }
          }

          pq.insert(item, score);
        }

        final sortedProperties = pq.toSortedList();

        // Keep selected property updated if it exists in the fetched list
        PropertyModel? updatedSelected = state.selectedProperty;
        if (updatedSelected != null) {
          final foundIndex =
              sortedProperties.indexWhere((p) => p.id == updatedSelected!.id);
          if (foundIndex != -1) {
            updatedSelected = sortedProperties[foundIndex];
          }
        }

        state = state.copyWith(
          properties: sortedProperties,
          isLoading: false,
          selectedProperty: updatedSelected,
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Failed to load properties';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred');
    }
  }

  void selectProperty(PropertyModel? property) {
    state = PropertiesState(
      properties: state.properties,
      isLoading: state.isLoading,
      error: state.error,
      selectedProperty: property,
      searchQuery: state.searchQuery,
      minRent: state.minRent,
      maxRent: state.maxRent,
      selectedType: state.selectedType,
      selectedAmenities: state.selectedAmenities,
    );
  }

  void updateFilters({
    double? minRent,
    double? maxRent,
    String? type,
    List<String>? amenities,
  }) {
    state = state.copyWith(
      minRent: minRent,
      maxRent: maxRent,
      selectedType: type == 'ALL' ? null : type,
      selectedAmenities: amenities,
    );
    // Refresh lists
    fetchProperties();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    // Refresh lists
    fetchProperties();
  }

  Future<bool> searchAndMoveMap(
      String query, MapController mapController) async {
    if (query.trim().isEmpty) return false;

    // Update local query state
    state = state.copyWith(searchQuery: query);

    try {
      // Call OpenStreetMap Nominatim geocoder (explicitly create a clean Dio instance to avoid sending auth headers)
      final cleanDio = Dio();
      final url = 'https://nominatim.openstreetmap.org/search';

      final response = await cleanDio.get(
        url,
        queryParameters: {
          'q': query,
          'format': 'jsonv2',
          'countrycodes': 'ke',
          'limit': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'Rent.ME Rental Marketplace Client',
          },
        ),
      );

      if (response.statusCode == 200 && (response.data as List).isNotEmpty) {
        final location = response.data[0];
        final lat = double.parse(location['lat']);
        final lon = double.parse(location['lon']);

        // Move map
        mapController.move(LatLng(lat, lon), 14.5);

        // Fetch properties around the new location
        fetchProperties(
          minLat: lat - 0.02,
          maxLat: lat + 0.02,
          minLng: lon - 0.02,
          maxLng: lon + 0.02,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('[Geocoding Error] $e');
      // If geocoding fails, fallback to simple backend filter text search
      fetchProperties();
      return false;
    }
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, PropertiesState>((ref) {
  return PropertiesNotifier(ref);
});
