import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/meeting_models.dart';

class MeetingService {
  // Thay đổi IP này thành địa chỉ IP của máy chạy Server Python
  // Ví dụ: 'http://192.168.1.5:5000'
  static const String _serverUrl = 'http://192.168.239.243:5000';

  IO.Socket? _socket;
  final StreamController<TranscriptMessage> _transcriptController =
      StreamController.broadcast();
  final StreamController<String> _statusController =
      StreamController.broadcast();

  bool _isRecording = false;

  // Stream để UI lắng nghe
  Stream<TranscriptMessage> get transcriptStream =>
      _transcriptController.stream;
  Stream<String> get statusStream => _statusController.stream;
  bool get isRecording => _isRecording;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    print("Connecting to $_serverUrl...");

    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
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

    // Lắng nghe kết quả trả về từ Python (Speechmatics)
    _socket!.on('transcript_response', (data) {
      print('[SERVICE] Raw data received: $data');
      print('Received: $data');
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

  // Gửi sự kiện bắt đầu phiên họp
  void startStreaming() {
    _socket?.emit('start_streaming');
    _isRecording = true;
    _statusController.add('Recording started');
  }

  // Gửi dữ liệu âm thanh (Bytes)
  // Trong thực tế, bạn sẽ gọi hàm này từ một Stream thu âm Audio
  void sendAudioData(List<int> bytes) {
    if (_socket != null && _socket!.connected && _isRecording) {
      _socket!.emit('audio_data', bytes);
    }
  }

  // Kết thúc phiên
  void stopStreaming() {
    _isRecording = false;
    // Logic backend Python tự xử lý khi socket đóng hoặc ta có thể emit một event 'stop' tùy chỉnh
    _socket?.disconnect(); // Hoặc gửi event stop tùy bạn
    _statusController.add('Recording stopped');
  }

  // Giả lập API lấy danh sách cuộc họp cũ (Vì code Python bạn chỉ có phần Live)
  Future<List<Meeting>> getPastMeetings() async {
    // Ở đây bạn nên gọi REST API thật. Vì chưa có nên trả về mock list
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Meeting(
          id: '1',
          title: 'Q4 Marketing Strategy',
          subtitle: '3 action items',
          date: 'Oct 26, 2023',
          status: 'Completed'),
      Meeting(
          id: '2',
          title: 'Project Phoenix',
          subtitle: 'Sync up',
          date: 'Oct 25, 2023',
          status: 'Completed'),
    ];
  }
}
