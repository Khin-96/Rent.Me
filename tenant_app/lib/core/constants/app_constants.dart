import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const String _configuredApiUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredApiUrl.isNotEmpty) {
      return _configuredApiUrl.endsWith('/api')
          ? _configuredApiUrl
          : '$_configuredApiUrl/api';
    }
    return kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  }

  static const double defaultLat = -1.2921;
  static const double defaultLng = 36.8219;
  static const double defaultZoom = 13.0;

  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';
}
