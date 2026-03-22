import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_notification.dart';
import '../services/team_notification_service.dart';
import '../services/user_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<UserNotificationItem> _items = [];
  int _unreadCount = 0;
  String? _boundUserId;
  StreamSubscription? _subscription;

  List<UserNotificationItem> get items => _items;
  int get unreadCount => _unreadCount;

  Future<void> bindUser(String? userId) async {
    if (userId == null || userId.isEmpty) {
      _boundUserId = null;
      _items = [];
      _unreadCount = 0;
      await _subscription?.cancel();
      _subscription = null;
      notifyListeners();
      return;
    }

    if (_boundUserId == userId) {
      return;
    }

    _boundUserId = userId;
    await _subscription?.cancel();
    _subscription = TeamNotificationService().notificationsStream.listen((item) {
      _items = [item, ..._items];
      _unreadCount += 1;
      notifyListeners();
    });
    await refresh();
  }

  Future<void> refresh() async {
    if (_boundUserId == null || _boundUserId!.isEmpty) {
      return;
    }
    final data = await UserNotificationService.fetchNotifications(
      userId: _boundUserId!,
    );
    _items = (data['notifications'] as List<UserNotificationItem>);
    _unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (_boundUserId == null || _boundUserId!.isEmpty) {
      return;
    }
    await UserNotificationService.markAllRead(userId: _boundUserId!);
    _items = _items
        .map(
          (item) => UserNotificationItem(
            id: item.id,
            userId: item.userId,
            title: item.title,
            body: item.body,
            type: item.type,
            payload: item.payload,
            isRead: true,
            createdAt: item.createdAt,
          ),
        )
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_boundUserId == null || _boundUserId!.isEmpty) {
      return;
    }

    final idx = _items.indexWhere((item) => item.id == notificationId);
    if (idx < 0) {
      return;
    }

    final item = _items[idx];
    await UserNotificationService.deleteNotification(
      userId: _boundUserId!,
      notificationId: notificationId,
    );

    _items = _items.where((n) => n.id != notificationId).toList();
    if (!item.isRead && _unreadCount > 0) {
      _unreadCount -= 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
