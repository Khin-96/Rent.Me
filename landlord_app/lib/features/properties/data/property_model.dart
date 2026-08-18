class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String type;
  final String status;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final List<String> images;
  final List<String> videos;
  final int? bedrooms;
  final int? bathrooms;
  final double? size;
  final String landlordId;
  final DateTime createdAt;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.status,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    required this.images,
    required this.videos,
    this.bedrooms,
    this.bathrooms,
    this.size,
    required this.landlordId,
    required this.createdAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) {
          if (e is Map) {
            return (e['cloudinaryUrl'] ?? e['url'] ?? '').toString();
          }
          return e.toString();
        }).where((url) => url.isNotEmpty).toList();
      }
      if (value is String) return value.isEmpty ? [] : value.split(',');
      return [];
    }

    return PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: ((json['price'] ?? json['rentAmount'] ?? 0) as num).toDouble(),
      type: json['type'] as String? ?? 'APARTMENT',
      status: json['status'] as String? ?? 'ACTIVE',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      amenities: parseList(json['amenities']),
      images: parseList(json['images']),
      videos: parseList(json['videos']),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      size: (json['size'] as num?)?.toDouble(),
      landlordId: json['landlordId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
