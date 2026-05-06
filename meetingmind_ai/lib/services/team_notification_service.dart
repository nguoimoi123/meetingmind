import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_notification.dart';
import 'notification_service.dart';
import 'dart:async';

class TeamNotificationService {
  TeamNotificationService._internal();
  static final TeamNotificationService _instance =
      TeamNotificationService._internal();
  factory TeamNotificationService() => _instance;

  IO.Socket? _socket;
  String? _userId;
  final StreamController<UserNotificationItem> _notificationController =
      StreamController<UserNotificationItem>.broadcast();

  Stream<UserNotificationItem> get notificationsStream =>
      _notificationController.stream;

  void connect(String userId) {
    if (_socket != null && _socket!.connected && _userId == userId) return;

    _connectInternal(userId);
  }

  Future<void> _connectInternal(String userId) async {
    _userId = userId;
    _socket?.dispose();
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    if (accessToken.isEmpty) {
      return;
    }

    _socket = IO.io(apiBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {
        'user_id': userId,
        if (accessToken.isNotEmpty) 'access_token': accessToken,
      },
    });

    _socket!.connect();

    _socket!.on('team_invite', (data) {
      final teamName = (data is Map && data['team_name'] != null)
          ? data['team_name'].toString()
          : 'Team';
      final teamId = (data is Map && data['team_id'] != null)
          ? data['team_id'].toString()
          : null;
      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Team Invite',
        body: 'You were invited to $teamName',
        payload: teamId == null ? null : 'team_invite:$teamId',
      );
    });

    _socket!.on('team_event_created', (data) {
      final title = (data is Map && data['title'] != null)
          ? data['title'].toString()
          : 'Team event';
      final teamId = (data is Map && data['team_id'] != null)
          ? data['team_id'].toString()
          : null;
      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Team Event',
        body: 'New event: $title',
        payload: teamId == null ? null : 'team_event:$teamId',
      );
    });

    _socket!.on('plan_upgrade_code_issued', (data) async {
      final code = (data is Map && data['code'] != null)
          ? data['code'].toString()
          : '';
      final plan = (data is Map && data['plan'] != null)
          ? data['plan'].toString()
          : 'plus';

      if (code.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_upgrade_code', code);
      await prefs.setString('pending_upgrade_plan', plan);

      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Upgrade code ready',
        body: 'Your $plan code: $code',
        payload: 'upgrade_code:$plan',
      );
    });

    _socket!.on('user_notification', (data) async {
      if (data is! Map) {
        return;
      }
      final item = UserNotificationItem.fromJson(data.cast<String, dynamic>());
      _notificationController.add(item);

      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: item.title,
        body: item.body,
        payload: 'app_notifications',
      );
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _userId = null;
  }
}
