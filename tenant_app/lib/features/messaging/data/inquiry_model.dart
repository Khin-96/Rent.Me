class InquiryModel {
  final String id;
  final String tenantId;
  final String landlordId;
  final String propertyId;
  final String subject;
  final String status;
  final bool isReadByLandlord;
  final bool isReadByTenant;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MessageModel> messages;
  final PropertySummary? property;
  final UserSummary? tenant;
  final UserSummary? landlord;

  const InquiryModel({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.propertyId,
    required this.subject,
    required this.status,
    required this.isReadByLandlord,
    required this.isReadByTenant,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.property,
    this.tenant,
    this.landlord,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    return InquiryModel(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      landlordId: json['landlordId'] as String,
      propertyId: json['propertyId'] as String,
      subject: json['subject'] as String,
      status: json['status'] as String,
      isReadByLandlord: json['isReadByLandlord'] as bool? ?? false,
      isReadByTenant: json['isReadByTenant'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List? ?? [])
          .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      property: json['property'] != null
          ? PropertySummary.fromJson(json['property'] as Map<String, dynamic>)
          : null,
      tenant: json['tenant'] != null
          ? UserSummary.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
      landlord: json['landlord'] != null
          ? UserSummary.fromJson(json['landlord'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MessageModel {
  final String id;
  final String inquiryId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.inquiryId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      inquiryId: json['inquiryId'] as String,
      senderId: json['senderId'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PropertySummary {
  final String id;
  final String name;
  final String address;
  final String? thumbnailUrl;

  const PropertySummary({
    required this.id,
    required this.name,
    required this.address,
    this.thumbnailUrl,
  });

  factory PropertySummary.fromJson(Map<String, dynamic> json) {
    return PropertySummary(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

class UserSummary {
  final String id;
  final String name;
  final String? avatarUrl;

  const UserSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
