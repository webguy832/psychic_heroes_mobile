class NotificationDto {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationDto({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] ?? json['notificationId'] ?? 0,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? json['body'] ?? '',
      isRead: json['isRead'] ?? json['read'] ?? false,
      createdAt: json['createdAt'] ?? json['date'] ?? '',
    );
  }
}
