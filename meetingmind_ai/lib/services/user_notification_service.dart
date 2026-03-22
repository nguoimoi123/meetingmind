import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user_notification.dart';

class UserNotificationService {
  static Future<Map<String, dynamic>> fetchNotifications({
    required String userId,
    int limit = 50,
  }) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/user/notifications/$userId?limit=$limit'),
    );
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode == 200) {
      final map = body as Map<String, dynamic>;
      final items = ((map['notifications'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => UserNotificationItem.fromJson(
                item.cast<String, dynamic>(),
              ))
          .toList();
      return {
        'notifications': items,
        'unread_count': map['unread_count'] ?? 0,
      };
    }

    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Failed to load notifications';
    throw Exception(message);
  }

  static Future<void> markAllRead({
    required String userId,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/user/notifications/$userId/read-all'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final message = body is Map && body['error'] != null
          ? body['error'].toString()
          : 'Failed to mark notifications as read';
      throw Exception(message);
    }
  }

  static Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    final res = await http.delete(
      Uri.parse('$apiBaseUrl/user/notifications/$userId/$notificationId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final message = body is Map && body['error'] != null
          ? body['error'].toString()
          : 'Failed to delete notification';
      throw Exception(message);
    }
  }
}
