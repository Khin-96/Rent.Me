class PropertyModel {
  final String id;
  final String landlordId;
  final String name;
  final String? description;
  final String type;
  final double latitude;
  final double longitude;
  final String address;
  final String? neighbourhood;
  final String city;
  final int rentAmount;
  final int? depositAmount;
  final String status;
  final DateTime? availableFrom;
  final bool isVerified;
  final List<String> amenities;
  final List<PropertyImageModel> images;
  final List<PropertyVideoModel> videos;
  final LandlordSummary? landlord;

  const PropertyModel({
    required this.id,
    required this.landlordId,
    required this.name,
    this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.neighbourhood,
    required this.city,
    required this.rentAmount,
    this.depositAmount,
    required this.status,
    this.availableFrom,
    required this.isVerified,
    required this.amenities,
    required this.images,
    required this.videos,
    this.landlord,
  });

  PropertyImageModel? get coverImage {
    if (images.isEmpty) return null;
    return images.firstWhere(
      (i) => i.isCover,
      orElse: () => images.first,
    );
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      landlordId: json['landlordId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      neighbourhood: json['neighbourhood'] as String?,
      city: json['city'] as String? ?? 'Nairobi',
      rentAmount: (json['rentAmount'] as num).toInt(),
      depositAmount: json['depositAmount'] != null
          ? (json['depositAmount'] as num).toInt()
          : null,
      status: json['status'] as String,
      availableFrom: json['availableFrom'] != null
          ? DateTime.parse(json['availableFrom'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      amenities: List<String>.from(json['amenities'] as List? ?? []),
      images: (json['images'] as List? ?? [])
          .map((i) => PropertyImageModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      videos: (json['videos'] as List? ?? [])
          .map((v) => PropertyVideoModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      landlord: json['landlord'] != null
          ? LandlordSummary.fromJson(json['landlord'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PropertyVideoModel {
  final String id;
  final String propertyId;
  final String cloudinaryPublicId;
  final String cloudinaryUrl;
  final String? thumbnailUrl;

  const PropertyVideoModel({
    required this.id,
    required this.propertyId,
    required this.cloudinaryPublicId,
    required this.cloudinaryUrl,
    this.thumbnailUrl,
  });

  factory PropertyVideoModel.fromJson(Map<String, dynamic> json) {
    return PropertyVideoModel(
      id: json['id'] as String? ?? json['cloudinaryPublicId'] as String? ?? '',
      propertyId: json['propertyId'] as String? ?? '',
      cloudinaryPublicId: json['cloudinaryPublicId'] as String? ?? '',
      cloudinaryUrl:
          json['cloudinaryUrl'] as String? ?? json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

class PropertyImageModel {
  final String id;
  final String propertyId;
  final String cloudinaryPublicId;
  final String cloudinaryUrl;
  final bool isCover;

  const PropertyImageModel({
    required this.id,
    required this.propertyId,
    required this.cloudinaryPublicId,
    required this.cloudinaryUrl,
    required this.isCover,
  });

  factory PropertyImageModel.fromJson(Map<String, dynamic> json) {
    return PropertyImageModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      cloudinaryPublicId: json['cloudinaryPublicId'] as String,
      cloudinaryUrl: json['cloudinaryUrl'] as String,
      isCover: json['isCover'] as bool? ?? false,
    );
  }
}

class LandlordSummary {
  final String id;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final bool verificationBadge;

  const LandlordSummary({
    required this.id,
    required this.name,
    this.phone,
    this.avatarUrl,
    required this.isVerified,
    required this.verificationBadge,
  });

  factory LandlordSummary.fromJson(Map<String, dynamic> json) {
    return LandlordSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationBadge: json['verificationBadge'] as bool? ?? false,
    );
  }
}
