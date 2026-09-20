import 'dart:convert';

enum NotificationType {
  weeklySummary,
  overspendAlert,
  nightlyReview,
  monthEndSummary,
  developerNotice,
  appUpdate,
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionTag;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionTag,
  });

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionTag,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionTag: actionTag ?? this.actionTag,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionTag': actionTag,
    };
  }

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    return AppNotificationItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.developerNotice,
      ),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      actionTag: map['actionTag'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotificationItem.fromJson(String source) =>
      AppNotificationItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
