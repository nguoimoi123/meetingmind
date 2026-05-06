import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/api_config.dart';
import '../models/meeting_models.dart';
import 'api_auth_headers.dart';

class MeetingService {
  IO.Socket get socket => _socket!;
  String? meetingSid;
  String? meetingTitle;
  String? contextFileContent;
  String _accessToken = '';

  static String get _serverUrl => apiBaseUrl;

  IO.Socket? _socket;
  final StreamController<TranscriptMessage> _transcriptController =
      StreamController.broadcast();
  final StreamController<String> _statusController =
      StreamController.broadcast();

  bool _isRecording = false;

  final String userId;

  MeetingService(this.userId);

  Stream<TranscriptMessage> get transcriptStream =>
      _transcriptController.stream;
  Stream<String> get statusStream => _statusController.stream;
  bool get isRecording => _isRecording;
  String? get currentMeetingSid => meetingSid ?? _socket?.id;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      meetingSid = currentMeetingSid;
      return;
    }

    print('Connecting to $_serverUrl...');

    final completer = Completer<void>();
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken') ?? '';

    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {
        'user_id': userId,
        if (_accessToken.isNotEmpty) 'access_token': _accessToken,
      },
    });

    _socket!.on('connect', (_) {
      meetingSid = currentMeetingSid;
      print('Socket SID = $meetingSid');
      print('Connected to Server');
      _statusController.add('Connected');
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _socket!.on('disconnect', (_) {
      print('Disconnected from Server');
      _statusController.add('Disconnected');
    });

    _socket!.on('status', (data) {
      final msg = (data is Map && data['msg'] != null)
          ? data['msg'].toString()
          : data.toString();
      print('Server Status: $msg');
      if (msg.toLowerCase().contains('unauthorized') ||
          msg.toLowerCase().contains('limit')) {
        _isRecording = false;
      }
      _statusController.add(msg);
    });

    _socket!.on('transcript_response', (data) {
      if (data is Map<String, dynamic>) {
        final msg = TranscriptMessage.fromJson(data);
        _transcriptController.add(msg);
        return;
      }
      if (data is Map) {
        final msg = TranscriptMessage.fromJson(
          data.map((key, value) => MapEntry(key.toString(), value)),
        );
        _transcriptController.add(msg);
      }
    });

    _socket!.on('error', (error) {
      print('Socket Error: $error');
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    });

    _socket!.on('connect_error', (error) {
      print('Socket Connect Error: $error');
      if (!completer.isCompleted) {
        completer.completeError(error ?? 'connect_error');
      }
    });

    _socket!.on('connect_timeout', (error) {
      print('Socket Connect Timeout: $error');
      if (!completer.isCompleted) {
        completer.completeError(error ?? 'connect_timeout');
      }
    });

    _socket!.connect();

    try {
      await completer.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      if (_socket?.connected == true) {
        meetingSid = currentMeetingSid;
      } else {
        rethrow;
      }
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _transcriptController.close();
    _statusController.close();
  }

  void startStreaming({String? title}) {
    final payload = <String, dynamic>{'user_id': userId};
    final payloadTitle = (title ?? meetingTitle)?.trim();
    if (payloadTitle != null && payloadTitle.isNotEmpty) {
      meetingTitle = payloadTitle;
      payload['title'] = payloadTitle;
    }
    if (_accessToken.isNotEmpty) {
      payload['access_token'] = _accessToken;
    }
    _socket?.emit('start_streaming', payload);
    _isRecording = true;
    _statusController.add('Recording started');
    Future<void>.delayed(
      const Duration(milliseconds: 250),
      _syncMeetingMeta,
    );
  }

  void sendAudioData(List<int> bytes) {
    if (_socket != null && _socket!.connected && _isRecording) {
      _socket!.emit('audio_data', bytes);
    }
  }

  void stopStreaming() {
    _isRecording = false;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('end_meeting');
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        _socket?.disconnect();
      });
    } else {
      _socket?.disconnect();
    }
    _statusController.add('Recording stopped');
  }

  void setSpeakerName({required String speakerId, required String name}) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('set_speaker_name', {
        'speaker_id': speakerId,
        'name': name,
      });
    }
  }

  Future<void> setMeetingContext({
    required String title,
    String? context,
  }) async {
    meetingTitle = title;
    contextFileContent = context;
    await _syncMeetingMeta();
  }

  Future<void> _syncMeetingMeta() async {
    final sid = currentMeetingSid;
    if (sid == null || meetingTitle == null) return;
    final uri = Uri.parse('$_serverUrl/meetings/$sid?user_id=$userId');
    try {
      final response = await http.put(
        uri,
        headers: await ApiAuthHeaders.build(json: true),
        body: jsonEncode({'title': meetingTitle}),
      );
      if (response.statusCode != 200) {
        print('Failed to sync meeting meta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing meeting meta: $e');
    }
  }

  Future<String?> waitForMeetingSid({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < timeout) {
      final sid = currentMeetingSid;
      if (sid != null && sid.isNotEmpty) {
        meetingSid = sid;
        return sid;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return currentMeetingSid;
  }

  Future<List<Meeting>> getPastMeetings() async {
    final uri = Uri.parse('$_serverUrl/meetings/?user_id=$userId');

    try {
      final response = await http
          .get(
            uri,
            headers: await ApiAuthHeaders.build(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.map((json) {
          final createdAt = DateTime.parse(json['created_at']);
          return Meeting(
            id: json['id'],
            title: json['title'],
            subtitle:
                json['status'] == 'completed' ? 'Completed' : 'In Progress',
            date: createdAt,
            time: DateFormat('HH:mm').format(createdAt),
            status: json['status'],
            participants: List<String>.from(
              json['participants'] ?? ['A', 'B', 'C'],
            ),
            tags: List<String>.from(json['tags'] ?? []),
          );
        }).toList();
      }
      throw Exception('Server Error');
    } catch (e) {
      print('Error fetching meetings: $e');
      return [];
    }
  }

  Future<void> deleteMeeting(String sid) async {
    final uri = Uri.parse('$_serverUrl/meetings/$sid');

    try {
      final response = await http
          .delete(
            uri,
            headers: await ApiAuthHeaders.build(),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete meeting');
      }
    } catch (e) {
      print('Error deleting meeting: $e');
      rethrow;
    }
  }
}
