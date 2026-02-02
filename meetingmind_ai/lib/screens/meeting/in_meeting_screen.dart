import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/services/summary_service.dart';
import 'package:meetingmind_ai/models/meeting_summary.dart';

class InMeetingScreen extends StatefulWidget {
  final String? title;
  final String? contextFilePath;
  final bool aiAgentEnabled;
  final String? openAiKey;

  const InMeetingScreen({
    super.key,
    this.title,
    this.contextFilePath,
    this.aiAgentEnabled = false,
    this.openAiKey,
  });

  @override
  State<InMeetingScreen> createState() => _InMeetingScreenState();
}

class _InMeetingScreenState extends State<InMeetingScreen>
    with SingleTickerProviderStateMixin {
  late MeetingService _meetingService;
  String _meetingTitle = 'Live Meeting';
  String? _contextText;
  String _plan = 'free';
  Map<String, dynamic> _limits = {};
  bool get _aiEnabled =>
      widget.aiAgentEnabled &&
      (PlanLimits.aiAgentAllowedFromLimits(_limits) || _plan != 'free');

  final TextEditingController _askController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final List<TranscriptMessage> _messages = [];
  final Map<String, String> _speakerNames = {};
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _audioStreamSubscription;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isDialogOpen = false;
  bool _isAskingAi = false;
  bool _isSummarizing = false;
  Timer? _meetingLimitTimer;

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
    final auth = context.read<AuthProvider>();
    final userId = auth.userId!;
    _plan = auth.plan;
    _limits = auth.limits;
    _meetingTitle = widget.title ?? _meetingTitle;
    _meetingService = MeetingService(userId);
    _connectAndStart();
  }

  Future<void> _readContextFile() async {
    // Luôn set title trước
    final title = widget.title ?? 'Live Meeting';
    setState(() => _meetingTitle = title);

    if (widget.contextFilePath != null) {
      try {
        final file = File(widget.contextFilePath!);
        final content = await file.readAsString();
        if (mounted) {
          _contextText = content;
          _meetingService.setMeetingContext(
            title: title,
            context: content,
          );
        }
      } catch (e) {
        print("Error reading context file: $e");
        // Vẫn set title ngay cả khi đọc file lỗi
        _meetingService.setMeetingContext(
          title: title,
          context: null,
        );
      }
    } else {
      // Không có file context, vẫn set title
      _meetingService.setMeetingContext(
        title: title,
        context: null,
      );
    }
  }

  @override
  void dispose() {
    _meetingLimitTimer?.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    _askController.dispose();
    _chatController.dispose();
    _stopRecording();
    _meetingService.disconnect();
    super.dispose();
  }

  Future<void> _connectAndStart() async {
    // Đặt title/context trước khi connect để server nhận meta ngay khi kết nối
    await _readContextFile();

    _meetingService.connect();
    _meetingService.startStreaming(title: _meetingTitle);

    final limitMinutes = PlanLimits.meetingDurationMinutesFromLimits(_limits) ??
        PlanLimits.meetingDurationMinutes(_plan);
    if (limitMinutes != null) {
      _meetingLimitTimer?.cancel();
      _meetingLimitTimer = Timer(Duration(minutes: limitMinutes), () async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Meeting time limit reached for $_plan plan. Ending meeting.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _handleEndMeeting();
      });
    }

    _meetingService.transcriptStream.listen((message) {
      print("📥 Nhận: ${message.speaker}: ${message.text}");
      if (!message.isFinal) return;

      if (mounted) {
        setState(() {
          String speakerId = message.speaker;
          if (!_speakerNames.containsKey(speakerId)) {
            if (!_isDialogOpen) {
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

  bool _isQuestionText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.contains('?') ||
        RegExp(
          r'^(who|what|when|where|why|how|which|can|could|should|would|do|does|did|is|are|am|will)\b',
          caseSensitive: false,
        ).hasMatch(trimmed);
  }

  String _buildTranscriptContext() {
    final lines =
        _messages.where((m) => m.isFinal && m.speaker != 'AI Agent').map((m) {
      final displayName = _speakerNames[m.speaker] ?? m.speaker;
      return "$displayName: ${m.text}";
    }).toList();

    return lines.join("\n");
  }

  void _openAskAiSheet() {
    if (!_aiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bạn cần bật AI Agent ở bước setup để sử dụng hỏi đáp.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hỏi AI dựa trên tài liệu',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _askController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Dán câu hoặc đoạn bạn muốn hỏi...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final q = _askController.text.trim();
                    if (q.isEmpty) return;
                    _askAiFromText(q);
                    Navigator.pop(ctx);
                  },
                  label: const Text('Gửi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _askAiFromText(String text) {
    String answer;
    final combinedContext = [
      if (_contextText != null && _contextText!.trim().isNotEmpty)
        _contextText!.trim(),
      _buildTranscriptContext(),
    ].where((c) => c.trim().isNotEmpty).join("\n\n");

    if (combinedContext.trim().isEmpty) {
      answer = _answerFreely(text);
    } else {
      final found = _answerFromContext(text, combinedContext);
      answer = found ??
          "Không tìm thấy thông tin trong tài liệu đã tải lên để trả lời câu hỏi này.";
    }

    final aiMsg = TranscriptMessage(
      speaker: 'AI Agent',
      text: answer,
      isFinal: true,
    );

    setState(() {
      _messages.add(aiMsg);
    });
    _scrollToBottom();
  }

  bool _isSummaryTooShort(MeetingSummary summary) {
    final summaryText = summary.summary.trim();
    final hasKeyPoints =
        summary.actionItems.isNotEmpty || summary.keyDecisions.isNotEmpty;
    if (summaryText.isEmpty && !hasKeyPoints) return true;
    if (summaryText.length < 20 && !hasKeyPoints) return true;
    return false;
  }

  Future<void> _handleEndMeeting() async {
    if (_isSummarizing) return;

    setState(() => _isSummarizing = true);
    await _pauseRecording();

    final sid = _meetingService.meetingSid;
    if (sid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chưa có SID cuộc họp")),
        );
      }
      if (mounted) setState(() => _isSummarizing = false);
      return;
    }

    try {
      final summary = await SummaryService.summarize(sid);

      if (_isSummaryTooShort(summary)) {
        if (!mounted) return;
        final choice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Cuộc họp quá ngắn"),
            content: const Text(
                "Không đủ dữ liệu để tóm tắt. Bạn muốn tiếp tục ghi âm hay kết thúc cuộc họp?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Kết thúc"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Tiếp tục"),
              ),
            ],
          ),
        );

        if (choice == true) {
          await _resumeRecording();
          if (mounted) setState(() => _isSummarizing = false);
          return;
        }

        _meetingService.stopStreaming();
        if (mounted) {
          setState(() => _isSummarizing = false);
          context.go('/app/meeting');
        }
        return;
      }

      _meetingService.stopStreaming();
      if (mounted) {
        setState(() => _isSummarizing = false);
        context.go('/post_summary/$sid');
      }
    } catch (e) {
      if (!mounted) return;
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Không thể tóm tắt"),
          content: const Text(
              "Cuộc họp có thể quá ngắn hoặc chưa đủ dữ liệu. Bạn muốn tiếp tục ghi âm hay kết thúc?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Kết thúc"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Tiếp tục"),
            ),
          ],
        ),
      );

      if (choice == true) {
        await _resumeRecording();
        if (mounted) setState(() => _isSummarizing = false);
        return;
      }

      _meetingService.stopStreaming();
      if (mounted) {
        setState(() => _isSummarizing = false);
        context.go('/app/meeting');
      }
    }
  }

  String? _answerFromContext(String question, String context) {
    // Simple heuristic: find sentences containing keywords from question
    final words = question
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toSet();

    if (words.isEmpty) return null;

    final sentences = context.split(RegExp(r'(?<=[.!?])\s+'));
    final matches = <String>[];
    for (final s in sentences) {
      final lower = s.toLowerCase();
      final hit = words.any((w) => lower.contains(w));
      if (hit) {
        matches.add(s.trim());
      }
      if (matches.length >= 2) break;
    }

    if (matches.isEmpty) {
      return "Không tìm thấy thông tin trong tài liệu đã tải lên để trả lời câu hỏi này.";
    }

    return "Dựa trên tài liệu đã tải lên:\n- ${matches.join("\n- ")}";
  }

  String _answerFreely(String question) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return "Bạn hãy đặt câu hỏi cụ thể hơn nhé.";
    return "Không có tài liệu đính kèm nên mình trả lời tự do theo hiểu biết chung.\n\nCâu hỏi của bạn: $trimmed";
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _speakerNames[speakerId] = name;
                  });
                  _meetingService.setSpeakerName(
                    speakerId: speakerId,
                    name: name,
                  );
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

      if (mounted) {
        setState(() {
          _isRecording = true;
          _isPaused = false;
        });
      }

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

  Future<void> _pauseRecording() async {
    if (!_isRecording || _isPaused) return;
    await _audioRecorder.stop();
    await _audioStreamSubscription?.cancel();
    if (mounted) setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    if (!_isRecording || !_isPaused) return;
    await _startRecording();
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    await _audioStreamSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    }
  }

  Widget _buildMessage(TranscriptMessage msg, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isAi = msg.speaker == 'AI Agent';
    String displayName = _speakerNames[msg.speaker] ?? msg.speaker;
    String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    // Lấy màu cho speaker
    int speakerIndex = _speakerNames.keys.toList().indexOf(msg.speaker);
    Color avatarColor = _speakerColors[speakerIndex % _speakerColors.length];
    final bool isQuestion = _aiEnabled && !isAi && _isQuestionText(msg.text);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAi ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.only(
          topRight: const Radius.circular(24),
          bottomRight:
              isAi ? const Radius.circular(4) : const Radius.circular(24),
          bottomLeft:
              isAi ? const Radius.circular(24) : const Radius.circular(4),
          topLeft: const Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isAi ? colorScheme.primary : avatarColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            msg.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color:
                  isAi ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              height: 1.5,
              fontWeight: msg.isFinal ? FontWeight.w400 : FontWeight.w300,
              fontStyle: msg.isFinal ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          if (isQuestion) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: colorScheme.primary.withOpacity(0.4)),
                ),
                child: Text(
                  'Chạm để hỏi AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ],
      ),
    );

    final bubbleWrapper = isQuestion
        ? InkWell(
            onTap: () {
              if (_isAskingAi) return;
              _askAiFromText(msg.text);
            },
            borderRadius: BorderRadius.circular(24),
            child: bubble,
          )
        : bubble;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAi ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isAi) ...[
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
          ],
          Flexible(child: bubbleWrapper),
          if (isAi) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withOpacity(0.15),
              child:
                  Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
            ),
          ]
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
              _meetingTitle,
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
                      final dotColor = _isPaused ? Colors.orange : Colors.red;
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: dotColor.withOpacity(
                                  _isPaused ? 0.5 : _pulseAnimation.value),
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
                    _isPaused ? 'Paused' : 'Recording...',
                    style: TextStyle(
                      color: _isPaused ? Colors.orange : Colors.red,
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
          if (_aiEnabled)
            IconButton(
              tooltip: 'Hỏi AI',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: _openAskAiSheet,
            ),
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
                          await _handleEndMeeting();
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
              padding: EdgeInsets.only(
                bottom: _aiEnabled ? 160 : 100,
              ), // Space cho input & FAB
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], context);
              },
            ),
          ),
          if (_aiEnabled)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        enabled: !_isAskingAi,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Hỏi AI về nội dung cuộc họp...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isAskingAi
                          ? null
                          : () {
                              final q = _chatController.text.trim();
                              if (q.isEmpty) return;
                              setState(() => _isAskingAi = true);
                              _chatController.clear();
                              _askAiFromText(q);
                              setState(() => _isAskingAi = false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                      child: _isAskingAi
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
      // FAB hiển thị trạng thái Micro
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _aiEnabled ? 96 : 24),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (!_isRecording) {
              _startRecording();
            } else if (_isPaused) {
              _resumeRecording();
            } else {
              _pauseRecording();
            }
          },
          backgroundColor: _isPaused ? Colors.orange : colorScheme.primary,
          icon: Icon(
            _isRecording
                ? (_isPaused ? Icons.play_arrow : Icons.pause)
                : Icons.mic_none,
          ),
          label: Text(
            _isRecording ? (_isPaused ? "Tiếp tục" : "Tạm dừng") : "Bắt đầu",
          ),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}
