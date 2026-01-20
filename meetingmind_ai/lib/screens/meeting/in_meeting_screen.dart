import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';

class InMeetingScreen extends StatefulWidget {
  const InMeetingScreen({super.key});

  @override
  State<InMeetingScreen> createState() => _InMeetingScreenState();
}

class _InMeetingScreenState extends State<InMeetingScreen> {
  late MeetingService _meetingService;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final List<TranscriptMessage> _messages = [];
  final Map<String, String> _speakerNames =
      {}; // Lưu tên tùy chỉnh cho speaker (id -> name)

  // Controller để cuộn danh sách tin nhắn
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _audioStreamSubscription;
  bool _isRecording = false;

  // Để tránh hiển thị dialog trùng lặp
  bool _isDialogOpen = false;
  String? _pendingSpeakerId;

  @override
  // void initState() {
  //   super.initState();
  //   _connectAndStart();
  // }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().userId!;
    _meetingService = MeetingService(userId);
    _connectAndStart();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stopRecording();
    _meetingService.disconnect();
    super.dispose();
  }

  Future<void> _connectAndStart() async {
    _meetingService.connect();
    _meetingService.startStreaming();

    _meetingService.transcriptStream.listen((message) {
      print("📥 Nhận: ${message.speaker}: ${message.text}");
      if (!message.isFinal) return;

      if (mounted) {
        setState(() {
          // Kiểm tra xem speaker này đã có tên chưa
          String speakerId = message.speaker;
          if (!_speakerNames.containsKey(speakerId)) {
            // Nếu chưa có tên và chưa mở dialog nào, thì chuẩn bị hỏi
            if (!_isDialogOpen) {
              _pendingSpeakerId = speakerId;
              // Sử dụng addPostFrameCallback để đảm bảo context đã sẵn sàng
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showSpeakerNameDialog(speakerId);
              });
            }
          }
          _messages.add(message);
        });

        // Tự động cuộn xuống cuối
        _scrollToBottom();
      }
    });

    await _startRecording();
  }

  void _scrollToBottom() {
    // delay một chút nhỏ để đảm bảo list đã render xong item mới
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        // Hoặc dùng animateTo cho mượt hơn
        // _scrollController.animateTo(
        //   _scrollController.position.maxScrollExtent,
        //   duration: const Duration(milliseconds: 300),
        //   curve: Curves.easeOut,
        // );
      }
    });
  }

  Future<void> _showSpeakerNameDialog(String speakerId) async {
    if (!mounted || _isDialogOpen) return;

    setState(() => _isDialogOpen = true);

    final TextEditingController nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User phải bấm nút mới tắt được
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nhận diện người nói mới'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Hệ thống phát hiện "$speakerId".'),
                SizedBox(height: 10),
                Text('Tên của họ là gì?'),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Ví dụ: Sếp Maria",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Bỏ qua'),
              onPressed: () {
                // Nếu bỏ qua thì giữ nguyên tên gốc
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Lưu tên'),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _speakerNames[speakerId] = nameController.text.trim();
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // Reset trạng thái dialog khi đóng
      if (mounted) {
        setState(() => _isDialogOpen = false);
        // Kiểm tra xem còn speaker nào chờ xử lý không (trường hợp tin nhắn đến nhanh)
        if (_pendingSpeakerId != null &&
            _speakerNames[_pendingSpeakerId!] == null) {
          // Nếu user bỏ qua thì không làm gì cả, đã lưu map rỗng rồi
        }
        _pendingSpeakerId = null;
      }
    });
  }

  // --- HÀM THU ÂM ---
  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cần cấp quyền Microphone!")),
        );
      }
      return;
    }

    try {
      const recordConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _audioRecorder.startStream(recordConfig);

      if (mounted) setState(() => _isRecording = true);

      _audioStreamSubscription = stream.listen((data) {
        if (data.length <= 5) return;
        // Gửi dữ liệu audio lên service
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
    if (mounted) setState(() => _isRecording = false);
  }

  Widget _buildMessage(TranscriptMessage msg, BuildContext context) {
    final theme = Theme.of(context);

    // Lấy tên hiển thị (Tên tùy chỉnh hoặc tên gốc)
    String displayName = _speakerNames[msg.speaker] ?? msg.speaker;
    String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    // Màu sắc xoay vòng dựa trên số lượng speaker đã biết
    int speakerIndex = _speakerNames.keys.toList().indexOf(msg.speaker);
    List<Color> avatarColors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal
    ];
    Color avatarColor = avatarColors[speakerIndex % avatarColors.length];
    Color bubbleColor = Colors.grey[100]!;

    return Align(
      alignment: Alignment.centerLeft, // Chat luôn bên trái
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor,
              child: Text(
                initial,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            // Chat Bubble
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(16),
                  // Bo góc bên trái nhỏ hơn nếu muốn style iMessage
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: avatarColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontStyle:
                            msg.isFinal ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        elevation: 0,
        actions: [
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
              _stopRecording();
              _meetingService.stopStreaming();

              final sid = _meetingService.meetingSid;
              print("➡️ Navigate to Summary with SID = $sid");

              if (sid != null) {
                context.go('/post_summary/$sid');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chưa có SID cuộc họp")),
                );
              }
            },
            icon: const Icon(Icons.stop_circle),
            label: const Text('End'),
            style: TextButton.styleFrom(foregroundColor: colorScheme.secondary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Recording Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: _isRecording ? colorScheme.primary : Colors.grey[400],
            child: Row(
              children: [
                Icon(
                    _isRecording
                        ? Icons.fiber_manual_record
                        : Icons.circle_outlined,
                    color: Colors.white,
                    size: 12),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? 'Recording...' : 'Ready',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Gắn controller vào đây
              padding: const EdgeInsets.symmetric(vertical: 16),
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
            _startRecording();
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
