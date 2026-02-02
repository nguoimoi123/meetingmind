import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/api_config.dart';

class MeetingService {
  IO.Socket get socket => _socket!;
  String? meetingSid;
  String? meetingTitle;
  String? contextFileContent;

  static const String _serverUrl = apiBaseUrl;

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

  void connect() {
    if (_socket != null && _socket!.connected) return;

    print("Connecting to $_serverUrl...");

    // Truyền user_id vào query params khi connect
    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'user_id': userId},
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      meetingSid = socket.id;
      print("🆔 Socket SID = $meetingSid");
      print('Connected to Server');
      _statusController.add('Connected');
      _syncMeetingMeta();
    });

    _socket!.on('disconnect', (_) {
      print('Disconnected from Server');
      _statusController.add('Disconnected');
    });

    _socket!.on('status', (data) {
      print('Server Status: ${data['msg']}');
    });

    _socket!.on('transcript_response', (data) {
      TranscriptMessage msg = TranscriptMessage.fromJson(data);
      _transcriptController.add(msg);
    });

    _socket!.on('error', (error) {
      print('Socket Error: $error');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void startStreaming({String? title}) {
    final payloadTitle = (title ?? meetingTitle)?.trim();
    if (payloadTitle != null && payloadTitle.isNotEmpty) {
      _socket?.emit('start_streaming', {'title': payloadTitle});
    } else {
      _socket?.emit('start_streaming');
    }
    _isRecording = true;
    _statusController.add('Recording started');
  }

  void sendAudioData(List<int> bytes) {
    if (_socket != null && _socket!.connected && _isRecording) {
      _socket!.emit('audio_data', bytes);
    }
  }

  void stopStreaming() {
    _isRecording = false;
    _socket?.disconnect();
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

  Future<void> setMeetingContext(
      {required String title, String? context}) async {
    meetingTitle = title;
    contextFileContent = context;
    await _syncMeetingMeta();
  }

  Future<void> _syncMeetingMeta() async {
    if (meetingSid == null || meetingTitle == null) return;
    final uri = Uri.parse('$_serverUrl/meetings/$meetingSid?user_id=$userId');
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': meetingTitle}),
      );
      if (response.statusCode != 200) {
        print("Failed to sync meeting meta: ${response.statusCode}");
      }
    } catch (e) {
      print("Error syncing meeting meta: $e");
    }
  }

  // API: lấy danh sách cuộc họp
  Future<List<Meeting>> getPastMeetings() async {
    final uri = Uri.parse('$_serverUrl/meetings?user_id=$userId');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
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
      } else {
        throw Exception('Server Error');
      }
    } catch (e) {
      print("Error fetching meetings: $e");
      return [];
    }
  }

  String _formatDate(String isoDate) {
    try {
      DateTime date = DateTime.parse(isoDate);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Unknown";
    }
  }

  Future<void> deleteMeeting(String sid) async {
    final uri = Uri.parse('$_serverUrl/meetings/$sid');

    try {
      final response =
          await http.delete(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete meeting');
      }
    } catch (e) {
      print("Error deleting meeting: $e");
      throw e;
    }
  }
}
