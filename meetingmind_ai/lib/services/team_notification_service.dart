import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import 'notification_service.dart';

class TeamNotificationService {
  TeamNotificationService._internal();
  static final TeamNotificationService _instance =
      TeamNotificationService._internal();
  factory TeamNotificationService() => _instance;

  IO.Socket? _socket;
  String? _userId;

  void connect(String userId) {
    if (_socket != null && _socket!.connected && _userId == userId) return;

    _userId = userId;
    _socket?.dispose();

    _socket = IO.io(apiBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'user_id': userId},
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
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _userId = null;
  }
}
