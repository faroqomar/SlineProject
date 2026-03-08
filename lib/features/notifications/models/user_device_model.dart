import 'package:flutter/foundation.dart';

/// Device row for FCM/APNs token registry (user_devices table).
/// Contract: .TODO/.../13_notification-routing/CONTRACT_notification_push.md
@immutable
class UserDevice {
  final String id;
  final String userId;
  final String fcmToken;
  final String platform;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserDevice({
    required this.id,
    required this.userId,
    required this.fcmToken,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      fcmToken: json['fcm_token'] as String? ?? '',
      platform: json['platform'] as String? ?? 'android',
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'fcm_token': fcmToken,
      'platform': platform,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
