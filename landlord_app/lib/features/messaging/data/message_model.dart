class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? propertyId;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? property;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.propertyId,
    required this.content,
    required this.createdAt,
    this.sender,
    this.property,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      propertyId: json['propertyId'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      sender: json['sender'] as Map<String, dynamic>?,
      property: json['property'] as Map<String, dynamic>?,
    );
  }
}

class ThreadSummary {
  final String otherUserId;
  final String otherUserName;
  final String? propertyId;
  final String? propertyTitle;
  final String lastMessage;
  final DateTime lastMessageAt;

  const ThreadSummary({
    required this.otherUserId,
    required this.otherUserName,
    this.propertyId,
    this.propertyTitle,
    required this.lastMessage,
    required this.lastMessageAt,
  });
}
