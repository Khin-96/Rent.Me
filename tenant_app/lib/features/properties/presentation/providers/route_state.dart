import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

enum TravelMode { walking, cycling, driving }

extension TravelModeExt on TravelMode {
  String get osrmProfile {
    switch (this) {
      case TravelMode.walking:
        return 'foot';
      case TravelMode.cycling:
        return 'bike';
      case TravelMode.driving:
        return 'driving';
    }
  }

  String get label {
    switch (this) {
      case TravelMode.walking:
        return 'Walking';
      case TravelMode.cycling:
        return 'Motorcycle';
      case TravelMode.driving:
        return 'Driving';
    }
  }

  // Average speeds in km/h for ETA
  double get avgSpeedKmh {
    switch (this) {
      case TravelMode.walking:
        return 5.0;
      case TravelMode.cycling:
        return 35.0;
      case TravelMode.driving:
        return 40.0;
    }
  }
}

class RouteResult {
  final TravelMode mode;
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;

  const RouteResult({
    required this.mode,
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });
}

class RouteState {
  final RouteResult? activeRoute;
  final bool isLoading;
  final String? error;
  final LatLng? destination;
  final TravelMode selectedMode;

  // Transient previews for all three modes shown in mode selector
  final Map<TravelMode, RouteResult?> previews;

  const RouteState({
    this.activeRoute,
    this.isLoading = false,
    this.error,
    this.destination,
    this.selectedMode = TravelMode.driving,
    this.previews = const {},
  });

  RouteState copyWith({
    RouteResult? activeRoute,
    bool? isLoading,
    String? error,
    LatLng? destination,
    TravelMode? selectedMode,
    Map<TravelMode, RouteResult?>? previews,
    bool clearRoute = false,
    bool clearError = false,
    bool clearDestination = false,
    bool clearActiveRoute = false,
  }) {
    return RouteState(
      activeRoute: clearRoute || clearActiveRoute
          ? null
          : (activeRoute ?? this.activeRoute),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      destination: clearDestination ? null : (destination ?? this.destination),
      selectedMode: selectedMode ?? this.selectedMode,
      previews: previews ?? this.previews,
    );
  }
}

class RouteNotifier extends StateNotifier<RouteState> {
  RouteNotifier() : super(const RouteState());

  final _dio = Dio();

  Future<RouteResult?> _fetchSingleRoute({
    required TravelMode mode,
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      final url = AppConstants.osrmRouteUrl(
        profile: mode.osrmProfile,
        startLng: start.longitude,
        startLat: start.latitude,
        destLng: destination.longitude,
        destLat: destination.latitude,
      );
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['routes'] != null) {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final firstRoute = routes[0];
          final distanceMeters =
              (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSecs =
              (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;
          final coordinates =
              firstRoute['geometry']['coordinates'] as List;

          final points = coordinates.map((coord) {
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          // For walking/cycling, OSRM returns foot/bike durations
          // Use returned duration for driving, recalculate for others
          final distanceKm = distanceMeters / 1000.0;
          final durationMin = mode == TravelMode.driving
              ? durationSecs / 60.0
              : (distanceKm / mode.avgSpeedKmh) * 60.0;

          return RouteResult(
            mode: mode,
            points: points,
            distanceKm: distanceKm,
            durationMin: durationMin,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  // Fetch previews for all 3 modes in parallel (for mode selector)
  Future<void> fetchAllPreviews({
    required LatLng start,
    required LatLng destination,
  }) async {
    state = state.copyWith(isLoading: true, destination: destination, clearError: true);

    final results = await Future.wait([
      _fetchSingleRoute(mode: TravelMode.walking, start: start, destination: destination),
      _fetchSingleRoute(mode: TravelMode.cycling, start: start, destination: destination),
      _fetchSingleRoute(mode: TravelMode.driving, start: start, destination: destination),
    ]);

    final previews = <TravelMode, RouteResult?>{
      TravelMode.walking: results[0],
      TravelMode.cycling: results[1],
      TravelMode.driving: results[2],
    };

    // Auto-select driving as active route
    state = state.copyWith(
      previews: previews,
      activeRoute: results[2],
      selectedMode: TravelMode.driving,
      isLoading: false,
    );
  }

  // Activate a specific mode's route
  void selectMode(TravelMode mode) {
    final route = state.previews[mode];
    state = state.copyWith(
      selectedMode: mode,
      activeRoute: route,
    );
  }

  // Fetch a single route directly (e.g., from property detail)
  Future<void> fetchRoute({
    required LatLng start,
    required LatLng destination,
    TravelMode mode = TravelMode.driving,
  }) async {
    state = state.copyWith(isLoading: true, destination: destination, clearError: true);
    final result = await _fetchSingleRoute(
        mode: mode, start: start, destination: destination);
    state = state.copyWith(
      activeRoute: result,
      clearActiveRoute: result == null,
      selectedMode: mode,
      isLoading: false,
    );
  }

  void clearRoute() {
    state = state.copyWith(
      clearRoute: true,
      previews: const {},
      clearDestination: true,
    );
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  return RouteNotifier();
});
