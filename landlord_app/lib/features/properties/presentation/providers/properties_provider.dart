import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../data/property_model.dart';

class PropertiesState {
  final List<PropertyModel> properties;
  final bool isLoading;
  final String? error;

  const PropertiesState({
    this.properties = const [],
    this.isLoading = false,
    this.error,
  });

  PropertiesState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    String? error,
  }) {
    return PropertiesState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PropertiesNotifier extends StateNotifier<PropertiesState> {
  final Ref _ref;

  PropertiesNotifier(this._ref) : super(const PropertiesState()) {
    fetchMyProperties();
  }

  Future<void> fetchMyProperties() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = _ref.read(prefsProvider);
      final userId = prefs.getString('user_id');
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'Not logged in');
        return;
      }
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/properties',
          queryParameters: {'landlordId': userId, 'limit': 50});
      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data is List
            ? response.data
            : (response.data['properties'] as List<dynamic>? ?? []);
        final list = dataList
            .map((j) => PropertyModel.fromJson(j as Map<String, dynamic>))
            .toList();
        state = PropertiesState(properties: list);
      }
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.response?.data['error']?.toString() ?? 'Failed to load');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error');
    }
  }

  Future<bool> toggleStatus(String id, String newStatus) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.patch('/properties/$id/status', data: {'status': newStatus});
      final updated = state.properties.map<PropertyModel>((p) {
        if (p.id == id) {
          return PropertyModel(
            id: p.id,
            title: p.title,
            description: p.description,
            price: p.price,
            type: p.type,
            status: newStatus,
            address: p.address,
            city: p.city,
            latitude: p.latitude,
            longitude: p.longitude,
            amenities: p.amenities,
            images: p.images,
            videos: p.videos,
            bedrooms: p.bedrooms,
            bathrooms: p.bathrooms,
            size: p.size,
            landlordId: p.landlordId,
            createdAt: p.createdAt,
          );
        }
        return p;
      }).toList();
      state = state.copyWith(properties: updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProperty(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete('/properties/$id');
      state = state.copyWith(
          properties: state.properties.where((p) => p.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PropertyModel?> createProperty(Map<String, dynamic> data) async {
    try {
      final dio = _ref.read(dioProvider);
      final Map<String, dynamic> body = Map.from(data);
      if (body.containsKey('title')) {
        body['name'] = body['title'];
        body.remove('title');
      }
      if (body.containsKey('price')) {
        body['rentAmount'] = (body['price'] as num).toInt();
        body.remove('price');
      }
      final response = await dio.post('/properties', data: body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> propertyData =
            response.data is Map && response.data.containsKey('property')
                ? response.data['property']
                : response.data;
        final property = PropertyModel.fromJson(propertyData);
        state = state.copyWith(properties: [property, ...state.properties]);
        return property;
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map && responseData['error'] != null
          ? responseData['error'].toString()
          : 'Failed to create property';
      state = state.copyWith(error: message);
    } catch (_) {
      state = state.copyWith(error: 'Failed to create property');
    }
    return null;
  }

  Future<bool> updateProperty(String id, Map<String, dynamic> data) async {
    try {
      final dio = _ref.read(dioProvider);
      final Map<String, dynamic> body = Map.from(data);
      if (body.containsKey('title')) {
        body['name'] = body['title'];
        body.remove('title');
      }
      if (body.containsKey('price')) {
        body['rentAmount'] = (body['price'] as num).toInt();
        body.remove('price');
      }
      final response = await dio.put('/properties/$id', data: body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> propertyData =
            response.data is Map && response.data.containsKey('property')
                ? response.data['property']
                : response.data;
        final updated = PropertyModel.fromJson(propertyData);
        state = state.copyWith(
            properties:
                state.properties.map((p) => p.id == id ? updated : p).toList());
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, PropertiesState>((ref) {
  return PropertiesNotifier(ref);
});
