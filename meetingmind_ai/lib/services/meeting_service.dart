import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../models/meeting_models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MeetingService {
  IO.Socket get socket => _socket!;
  String? meetingSid;

  static final String? _serverUrl = dotenv.env['API_BASE_URL'];

  IO.Socket? _socket;
  final StreamController<TranscriptMessage> _transcriptController =
      StreamController.broadcast();
  final StreamController<String> _statusController =
      StreamController.broadcast();

  bool _isRecording = false;

  // User ID giả lập, thực tế lấy từ AuthService
  final String _currentUserId = "user_123";

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
      'query': {'user_id': _currentUserId},
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      meetingSid = socket.id;
      print("🆔 Socket SID = $meetingSid");
      print('Connected to Server');
      _statusController.add('Connected');
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

  void startStreaming() {
    _socket?.emit('start_streaming');
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

  // API LẤY DANH SÁCH CỰA HỌP (Thay vì Mock)
  Future<List<Meeting>> getPastMeetings() async {
    final uri = Uri.parse('$_serverUrl/meetings?user_id=$_currentUserId');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          // Format lại ngày tháng cho đẹp
          String dateStr = json['created_at'] ?? '';
          return Meeting(
            id: json['id'],
            title: json['title'],
            subtitle:
                json['status'] == 'completed' ? 'Completed' : 'In Progress',
            date: _formatDate(dateStr),
            status: json['status'],
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
