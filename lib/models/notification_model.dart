class NotificationDto {
  final int id;
  final String title;
  final String senderName;
  final String message;
  final bool isRead;
  final String createdAt;
  final int? notificationType;

  NotificationDto({
    required this.id,
    required this.title,
    required this.senderName,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.notificationType,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final sender = (json['senderName'] ?? json['title'] ?? 'System').toString();
    final detail = (json['notificationDetail'] ?? json['message'] ?? json['body'] ?? '').toString();
    final read = json['isMarkRead'] == true || json['isRead'] == true || json['read'] == true;
    final idVal = json['notificationId'] ?? json['id'] ?? 0;
    final dateVal = (json['createdON'] ?? json['createdOn'] ?? json['createdAt'] ?? json['date'] ?? '').toString();
    
    int parsedId = 0;
    if (idVal is int) {
      parsedId = idVal;
    } else if (idVal != null) {
      parsedId = int.tryParse(idVal.toString()) ?? 0;
    }

    int? parsedType;
    if (json['notificationType'] != null) {
      parsedType = int.tryParse(json['notificationType'].toString());
    }

    return NotificationDto(
      id: parsedId,
      title: sender.isNotEmpty ? sender : 'Notification',
      senderName: sender,
      message: detail,
      isRead: read,
      createdAt: dateVal,
      notificationType: parsedType,
    );
  }

  NotificationDto copyWith({
    int? id,
    String? title,
    String? senderName,
    String? message,
    bool? isRead,
    String? createdAt,
    int? notificationType,
  }) {
    return NotificationDto(
      id: id ?? this.id,
      title: title ?? this.title,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      notificationType: notificationType ?? this.notificationType,
    );
  }
}
