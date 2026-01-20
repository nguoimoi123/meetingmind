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

class _InMeetingScreenState extends State<InMeetingScreen>
    with SingleTickerProviderStateMixin {
  late MeetingService _meetingService;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final List<TranscriptMessage> _messages = [];
  final Map<String, String> _speakerNames = {};
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _audioStreamSubscription;
  bool _isRecording = false;
  bool _isDialogOpen = false;
  String? _pendingSpeakerId;

  // Animation cho hiệu ứng thu âm
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Màu sắc rực rỡ cho speaker
  static const List<Color> _speakerColors = [
    Color(0xFF2962FF), // Xanh đậm
    Color(0xFF6200EA), // Tím
    Color(0xFF00C853), // Xanh lá
    Color(0xFFFF6D00), // Cam
    Color(0xFFD50000), // Đỏ
    Color(0xFF00B0FF), // Xanh da trời
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); // Lặp lại animation

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().userId!;
    _meetingService = MeetingService(userId);
    _connectAndStart();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
          String speakerId = message.speaker;
          if (!_speakerNames.containsKey(speakerId)) {
            if (!_isDialogOpen) {
              _pendingSpeakerId = speakerId;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showSpeakerNameDialog(speakerId);
              });
            }
          }
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });

    await _startRecording();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showSpeakerNameDialog(String speakerId) async {
    if (!mounted || _isDialogOpen) return;

    setState(() => _isDialogOpen = true);
    final TextEditingController nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Phát hiện người nói mới',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Hệ thống ghi nhận người nói "$speakerId".'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Nhập tên (Ví dụ: Sếp Maria)",
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _speakerNames[speakerId] = nameController.text.trim();
                  });
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lưu tên'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isDialogOpen = false);
        _pendingSpeakerId = null;
      }
    });
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cần cấp quyền Microphone để bắt đầu!"),
            behavior: SnackBarBehavior.floating,
          ),
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
    String displayName = _speakerNames[msg.speaker] ?? msg.speaker;
    String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    // Lấy màu cho speaker
    int speakerIndex = _speakerNames.keys.toList().indexOf(msg.speaker);
    Color avatarColor = _speakerColors[speakerIndex % _speakerColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Speaker với màu rực rỡ
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Message Card
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(4),
                  topLeft: Radius.circular(4), // Góc trên trái bo nhẹ
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: avatarColor, // Tên cùng màu avatar
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    msg.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                      fontWeight: msg.isFinal
                          ? FontWeight.w400
                          : FontWeight.w300, // Text nhẹ hơn nếu chưa chốt
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Live Meeting',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            // Recording Status Indicator ở dưới title
            if (_isRecording)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.red.withOpacity(_pulseAnimation.value),
                              blurRadius: 4,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recording...',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Nút End Meeting (Nút bấm tròn màu đỏ nổi bật)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Xác nhận kết thúc
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Kết thúc cuộc họp?"),
                    content: const Text(
                        "Hệ thống sẽ ngừng ghi âm và chuyển sang trang tổng kết."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Hủy"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context); // Đóng dialog
                          _stopRecording();
                          _meetingService.stopStreaming();

                          final sid = _meetingService.meetingSid;
                          if (sid != null) {
                            context.go('/post_summary/$sid');
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Chưa có SID cuộc họp")),
                              );
                            }
                          }
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text("Kết thúc"),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.call_end, color: Colors.red, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "End",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 100), // Space cho FAB
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], context);
              },
            ),
          ),
        ],
      ),
      // FAB hiển thị trạng thái Micro
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!_isRecording) {
            _startRecording();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Đang ghi âm rồi..."),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          }
        },
        backgroundColor: colorScheme.primary,
        icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
        label: Text(_isRecording ? "Đang thu âm" : "Bắt đầu"),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
