import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String categoryLabel;
  final double latitude;
  final double longitude;
  final double distanceM;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.latitude,
    required this.longitude,
    required this.distanceM,
  });
}

class NearbyPlacesService {
  static final _dio = Dio();

  // Amenity → human-readable label
  static const Map<String, String> _amenityLabels = {
    'supermarket': 'Supermarket',
    'hospital': 'Hospital',
    'clinic': 'Clinic',
    'pharmacy': 'Pharmacy',
    'school': 'School',
    'university': 'University',
    'bank': 'Bank',
    'atm': 'ATM',
    'fuel': 'Petrol Station',
    'bus_stop': 'Bus Stop',
    'gym': 'Gym',
    'restaurant': 'Restaurant',
    'cafe': 'Cafe',
    'park': 'Park',
    'mall': 'Shopping Centre',
  };

  static Future<List<PlaceModel>> fetchNearby({
    required double lat,
    required double lng,
    int radiusMeters = 1000,
    int maxResults = 12,
  }) async {
    final amenityList = _amenityLabels.keys.join('|');

    // Overpass QL query — fetch nodes matching any of our target amenities
    final query = '''
[out:json][timeout:15];
(
  node["amenity"~"$amenityList"](around:$radiusMeters,$lat,$lng);
  node["leisure"="park"](around:$radiusMeters,$lat,$lng);
  node["shop"="mall"](around:$radiusMeters,$lat,$lng);
);
out body $maxResults;
''';

    try {
      final response = await _dio.post(
        AppConstants.overpassUrl,
        data: 'data=${Uri.encodeComponent(query)}',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      if (response.statusCode != 200) return [];
      final elements = response.data['elements'] as List? ?? [];

      final places = <PlaceModel>[];
      for (final el in elements) {
        if (el is! Map) continue;
        final tags = el['tags'] as Map? ?? {};
        final name = (tags['name'] ?? tags['amenity'] ?? '').toString();
        if (name.isEmpty) continue;

        final pLat = (el['lat'] as num?)?.toDouble();
        final pLng = (el['lon'] as num?)?.toDouble();
        if (pLat == null || pLng == null) continue;

        final amenity = (tags['amenity'] ?? tags['leisure'] ?? tags['shop'] ?? '').toString();
        final label = _amenityLabels[amenity] ?? 'Place';

        final distanceM = _haversineM(lat, lng, pLat, pLng);

        places.add(PlaceModel(
          id: el['id'].toString(),
          name: name,
          category: amenity,
          categoryLabel: label,
          latitude: pLat,
          longitude: pLng,
          distanceM: distanceM,
        ));
      }

      places.sort((a, b) => a.distanceM.compareTo(b.distanceM));
      return places.take(maxResults).toList();
    } catch (_) {
      return [];
    }
  }

  static double _haversineM(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final phi1 = lat1 * 3.141592653589793 / 180;
    final phi2 = lat2 * 3.141592653589793 / 180;
    final dphi = (lat2 - lat1) * 3.141592653589793 / 180;
    final dlambda = (lng2 - lng1) * 3.141592653589793 / 180;
    final a = _sin2(dphi / 2) + _cos(phi1) * _cos(phi2) * _sin2(dlambda / 2);
    return r * 2 * _atan2(_sqrt(a), _sqrt(1 - a));
  }

  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => _approxSin(x);
  static double _cos(double x) => _approxSin(x + 1.5707963267948966);
  static double _sqrt(double x) => x <= 0 ? 0 : x < 1e-10 ? x : _sqrtNewton(x);
  static double _atan2(double y, double x) {
    if (x == 0) return y > 0 ? 1.5707963267948966 : -1.5707963267948966;
    final r = y / x;
    final a = r / (1 + 0.28125 * r * r);
    return x < 0 ? (y >= 0 ? a + 3.141592653589793 : a - 3.141592653589793) : a;
  }

  static double _approxSin(double x) {
    x = x % (2 * 3.141592653589793);
    if (x > 3.141592653589793) x -= 2 * 3.141592653589793;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  static double _sqrtNewton(double x) {
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
