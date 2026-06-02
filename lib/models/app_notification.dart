class AppNotificationType {
  static const chat = 'chat';
  static const match = 'match';
  static const help = 'help';
  static const system = 'system';
}

class AppNotification {
  final String id;
  final int? serverId;
  final String type;
  final String title;
  final String body;
  final String? sourceType;
  final String? sourceId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    this.serverId,
    required this.type,
    required this.title,
    required this.body,
    this.sourceType,
    this.sourceId,
    required this.createdAt,
    required this.isRead,
  });

  AppNotification copyWith({
    String? id,
    int? serverId,
    String? type,
    String? title,
    String? body,
    String? sourceType,
    String? sourceId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serverId': serverId,
      'type': type,
      'title': title,
      'body': body,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawServerId = json['serverId'] ?? json['server_id'];
    final serverId = rawServerId is num
        ? rawServerId.toInt()
        : int.tryParse(rawServerId?.toString() ?? '');
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];

    return AppNotification(
      id: json['id'] as String? ?? '',
      serverId: serverId,
      type: json['type'] as String? ?? AppNotificationType.system,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      sourceType: (json['sourceType'] ?? json['source_type'])?.toString(),
      sourceId: (json['sourceId'] ?? json['source_id'])?.toString(),
      createdAt:
          DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
