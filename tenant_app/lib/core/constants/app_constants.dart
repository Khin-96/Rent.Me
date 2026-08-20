import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const String _configuredApiUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredApiUrl.isNotEmpty) {
      final configuredUrl = _configuredApiUrl.trim().replaceFirst(
            RegExp(r'/+$'),
            '',
          );
      return configuredUrl.endsWith('/api')
          ? configuredUrl
          : '$configuredUrl/api';
    }
    return kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  }

  // Default map center — Nairobi CBD
  static const double defaultLat = -1.2921;
  static const double defaultLng = 36.8219;
  static const double defaultZoom = 13.5;

  // OpenFreeMap Liberty is a MapLibre vector style, not a raster PNG tile URL.
  static const String openFreeMapStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';

  // Raster fallback while the style loads or if it is unavailable.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmFallbackUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Nominatim for search suggestions
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';

  // OSRM routing — supports 'driving', 'foot', 'bike' profiles
  static const String osrmBaseUrl = 'https://router.project-osrm.org/route/v1';

  static String osrmRouteUrl({
    required String profile,
    required double startLng,
    required double startLat,
    required double destLng,
    required double destLat,
  }) {
    return '$osrmBaseUrl/$profile/$startLng,$startLat;$destLng,$destLat'
        '?overview=full&geometries=geojson';
  }

  // Overpass API for nearby places
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';

  // Route colors
  static const double routeStrokeWidth = 5.5;
  static const double routeBorderWidth = 2.0;
}
