import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:go_router/go_router.dart';
// Đã xóa dòng import trùng lặp
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';

class InMeetingScreen extends StatefulWidget {
  const InMeetingScreen({super.key});

  @override
  State<InMeetingScreen> createState() => _InMeetingScreenState();
}

class _InMeetingScreenState extends State<InMeetingScreen> {
  final MeetingService _meetingService = MeetingService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final List<TranscriptMessage> _messages = [];

  StreamSubscription? _audioStreamSubscription;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _connectAndStart();
  }

  Future<void> _connectAndStart() async {
    // 1. Kết nối Socket
    _meetingService.connect();

    // 2. Gửi event start_streaming để server chuẩn bị
    _meetingService.startStreaming();

    // 3. Lắng nghe kết quả trả về từ Server
    _meetingService.transcriptStream.listen((message) {
      if (!message.isFinal) return;
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
      }
    });

    // 4. Bắt đầu thu âm từ Mic
    await _startRecording();
  }

  // --- HÀM THU ÂM THỰC TẾ ---
  Future<void> _startRecording() async {
    // Kiểm tra quyền
    if (!await _audioRecorder.hasPermission()) {
      // SỬA LỖI: Thêm kiểm tra 'mounted' trước khi dùng context sau await
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cần cấp quyền Microphone!")),
        );
      }
      return;
    }

    try {
      // Cấu hình thu âm
      // LƯU Ý: Đã bỏ audioSource vì thư viện của bạn không hỗ trợ tên này.
      // Mặc định sẽ lấy Microphone.
      const recordConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Bắt đầu stream thu âm
      final stream = await _audioRecorder.startStream(recordConfig);

      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }

      // Lắng nghe từng đoạn dữ liệu âm thanh (chunks)
      _audioStreamSubscription = stream.listen((data) {
        if (data.length <= 5) return;

        // CẮT HEADER
        final pcm = data.sublist(5);
        // data là Uint8List (dữ liệu nhị phân âm thanh)
        // Gửi thẳng lên Service để đẩy lên Socket
        _meetingService.sendAudioData(data);
      }, onError: (e) {
        print("Lỗi thu âm: $e");
        if (mounted) setState(() => _isRecording = false);
      }, onDone: () {
        print("Luồng thu âm kết thúc");
        if (mounted) setState(() => _isRecording = false);
      });
    } catch (e) {
      print("Không thể bắt đầu thu âm: $e");
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    await _audioStreamSubscription?.cancel();
    if (mounted) {
      setState(() => _isRecording = false);
    }
  }

  @override
  void dispose() {
    _stopRecording();
    _meetingService.disconnect();
    super.dispose();
  }

  Widget _buildMessage(TranscriptMessage msg, BuildContext context) {
    final theme = Theme.of(context);
    Color avatarColor =
        msg.speaker.contains('1') ? Colors.blue[100]! : Colors.purple[100]!;
    String speakerInitial = msg.speaker.replaceAll(RegExp(r'[^0-9]'), '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: avatarColor,
            child: Text(
              speakerInitial.isEmpty ? "?" : speakerInitial,
              style: TextStyle(
                  color: avatarColor == Colors.blue[100]
                      ? Colors.blue[800]
                      : Colors.purple[800],
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.speaker,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: msg.isFinal
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.5), // Sửa warning withOpacity
                    fontStyle:
                        msg.isFinal ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Meeting'),
        actions: [
          // Hiển thị trạng thái Mic
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Row(
                  children: const [
                    Icon(Icons.mic, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text("REC",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          TextButton.icon(
            onPressed: () {
              _stopRecording(); // Dừng mic
              _meetingService.stopStreaming(); // Dừng socket
              context.pushReplacement('/post_summary');
            },
            icon: const Icon(Icons.stop_circle),
            label: const Text('End'),
            style: TextButton.styleFrom(foregroundColor: colorScheme.secondary),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: colorScheme.primary,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.red
                        : Colors.grey, // Đỏ nếu đang thu
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_isRecording ? 'Recording...' : 'Ready',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], context);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!_isRecording) {
            _startRecording(); // Cho phép bật lại nếu đã tắt
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Microphone is already active")),
              );
            }
          }
        },
        backgroundColor: colorScheme.primary,
        child: Icon(_isRecording ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
