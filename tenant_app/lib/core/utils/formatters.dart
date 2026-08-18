import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(int amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return 'KSh ${formatter.format(amount)}';
  }

  static String currencyShort(int amount) {
    if (amount >= 1000) {
      return 'KSh ${(amount / 1000).toStringAsFixed(0)}k';
    }
    return currency(amount);
  }

  static String propertyType(String type) {
    switch (type) {
      case 'BEDSITTER':
        return 'Bedsitter';
      case 'STUDIO':
        return 'Studio';
      case 'ONE_BED':
        return '1 Bedroom';
      case 'TWO_BED':
        return '2 Bedroom';
      case 'THREE_BED_PLUS':
        return '3 Bedroom+';
      case 'APARTMENT':
        return 'Apartment';
      case 'HOUSE':
        return 'House';
      case 'VILLA':
        return 'Villa';
      case 'COMMERCIAL':
        return 'Commercial';
      default:
        return type;
    }
  }

  static String amenityLabel(String amenity) {
    switch (amenity) {
      case 'WATER':
        return 'Water';
      case 'PARKING':
        return 'Parking';
      case 'SECURITY':
        return 'Security';
      case 'WIFI':
        return 'Wi-Fi';
      case 'ELECTRICITY':
        return 'Electricity';
      case 'BALCONY':
        return 'Balcony';
      case 'LAUNDRY':
        return 'Laundry';
      case 'GYM':
        return 'Gym';
      case 'SWIMMING_POOL':
        return 'Pool';
      case 'FURNISHED':
        return 'Furnished';
      case 'GENERATOR':
        return 'Generator';
      case 'CCTV':
        return 'CCTV';
      default:
        return amenity;
    }
  }

  static String timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    if (duration.inDays < 7) return '${duration.inDays}d ago';
    return DateFormat('d MMM').format(date);
  }
}
