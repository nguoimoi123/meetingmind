import 'dart:async';
import 'dart:convert';
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
import 'package:http/http.dart' as http;
import 'package:docx_to_text/docx_to_text.dart';
import 'package:meetingmind_ai/features/meeting/logic/in_meeting_logic.dart';
import 'package:meetingmind_ai/features/meeting/presentation/widgets/meeting_transcript_message.dart';

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
  String? _openAiKey;
  String _plan = 'free';
  Map<String, dynamic> _limits = {};
  bool get _aiEnabled =>
      widget.aiAgentEnabled &&
      (PlanLimits.aiAgentAllowedFromLimits(_limits) ||
          PlanLimits.aiAgentAllowed(_plan));
  bool get _premiumAgentEnabled =>
      InMeetingLogic.isPremiumInMeetingAgentEnabled(
        aiAgentEnabled: widget.aiAgentEnabled,
        plan: _plan,
        limits: _limits,
      );

  final TextEditingController _askController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final List<TranscriptMessage> _messages = [];
  final Map<String, String> _speakerNames = {};
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _audioStreamSubscription;
  StreamSubscription<TranscriptMessage>? _transcriptStreamSubscription;
  StreamSubscription<String>? _statusStreamSubscription;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isDialogOpen = false;
  bool _isAskingAi = false;
  bool _isPremiumAgentThinking = false;
  bool _isSummarizing = false;
  Timer? _meetingLimitTimer;
  Timer? _premiumAgentDebounce;
  bool _hasInitialized = false;
  final Set<String> _premiumHandledMessages = {};
  bool _scrollScheduled = false;

  // Animation cho hiệu ứng thu âm
  late AnimationController _pulseController;
  // ignore: unused_field
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
    if (_hasInitialized) return;
    _hasInitialized = true;
    final auth = context.read<AuthProvider>();
    final userId = auth.userId!;
    _plan = auth.plan;
    _limits = auth.limits;
    _openAiKey = widget.openAiKey?.trim();
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
        final lowerPath = widget.contextFilePath!.toLowerCase();
        final ext = lowerPath.contains('.') ? lowerPath.split('.').last : '';
        if (ext.isNotEmpty && ext != 'txt' && ext != 'docx') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI Agent hiện chỉ hỗ trợ file TXT hoặc DOCX.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _contextText = null;
          _meetingService.setMeetingContext(
            title: title,
            context: null,
          );
          return;
        }
        final file = File(widget.contextFilePath!);
        String content;
        if (ext == 'docx') {
          final bytes = await file.readAsBytes();
          content = docxToText(bytes);
        } else {
          content = await file.readAsString();
        }
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
    _premiumAgentDebounce?.cancel();
    _statusStreamSubscription?.cancel();
    _transcriptStreamSubscription?.cancel();
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

    try {
      await _meetingService.connect();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể kết nối cuộc họp. Vui lòng thử lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    _statusStreamSubscription?.cancel();
    _statusStreamSubscription = _meetingService.statusStream.listen((status) {
      if (!mounted) return;

      final normalized = status.toLowerCase();
      if (normalized.contains('unauthorized')) {
        _stopRecording();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (normalized.contains('meeting limit')) {
        _stopRecording();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
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

    _transcriptStreamSubscription?.cancel();
    _transcriptStreamSubscription =
        _meetingService.transcriptStream.listen((TranscriptMessage message) {
      print("📥 Nhận: ${message.speaker}: ${message.text}");
      if (!mounted) return;

      setState(() {
        if (!message.isFinal) {
          final partialIndex = _messages.lastIndexWhere(
            (m) => !m.isFinal && m.speaker == message.speaker,
          );
          if (partialIndex >= 0) {
            _messages[partialIndex] = message;
          } else {
            _messages.add(message);
          }
          return;
        }

        _messages
            .removeWhere((m) => !m.isFinal && m.speaker == message.speaker);

        // Do not auto-open speaker dialog during live transcript to avoid UI lock.
        _messages.add(message);
      });
      _scrollToBottom();
    });

    await _startRecording();
  }

  void _scrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;
      final max = position.maxScrollExtent;
      if (!max.isFinite) return;
      final delta = (max - position.pixels).abs();
      if (delta < 24) {
        _scrollController.jumpTo(max);
        return;
      }
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
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

  String _sanitizeAiAnswer(String text) {
    return text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'(?m)^\s*#{1,6}\s*'), '')
        .replaceAll(RegExp(r'(?m)^\s*[-•]+\s*'), '')
        .replaceAll(RegExp(r'(?m)^\s*//+\s*'), '')
        .replaceAll(RegExp(r'(?m)^\s*\d+\.\s+'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  bool _shouldShowAiAnswerPrompt(TranscriptMessage message) {
    if (!_aiEnabled || !message.isFinal || message.speaker == 'AI Agent') {
      return false;
    }

    final key = InMeetingLogic.buildMessageKey(message);
    if (_premiumHandledMessages.contains(key)) {
      return false;
    }

    return _isQuestionText(message.text);
  }

  void _maybeTriggerPremiumAgent(TranscriptMessage message) {
    if (!InMeetingLogic.shouldPremiumAgentAutoRespond(
      message: message,
      premiumAgentEnabled: _premiumAgentEnabled,
      handledMessageKeys: _premiumHandledMessages,
    )) {
      return;
    }

    _premiumHandledMessages.add(InMeetingLogic.buildMessageKey(message));
    _premiumAgentDebounce?.cancel();
    _premiumAgentDebounce = Timer(
      const Duration(milliseconds: 900),
      () => _handlePremiumAgentQuestion(message),
    );
  }

  Future<void> _handlePremiumAgentQuestion(TranscriptMessage message) async {
    if (!_premiumAgentEnabled || _isPremiumAgentThinking || _isAskingAi) {
      return;
    }

    if (mounted) {
      setState(() => _isPremiumAgentThinking = true);
    }

    try {
      final combinedContext = InMeetingLogic.buildCombinedContext(
        documentContext: _contextText,
        messages: _messages,
        speakerNames: _speakerNames,
        preferRecentTranscript: true,
      );
      final answer = await _resolveAiAnswer(
        question: message.text,
        combinedContext: combinedContext,
        allowGeneralKnowledge: true,
        speakerName: _speakerNames[message.speaker] ?? message.speaker,
        isProactive: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          TranscriptMessage(
            speaker: 'AI Agent',
            text:
                'Agent note for ${_speakerNames[message.speaker] ?? message.speaker}:\n$answer',
            isFinal: true,
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isPremiumAgentThinking = false);
      }
    }
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

  Future<String> _askOpenAi({
    required String question,
    required String context,
  }) async {
    final key = _openAiKey;
    if (key == null || key.isEmpty) {
      throw Exception('Missing OpenAI API key');
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final systemPrompt =
        'Bạn là trợ lý họp. Chỉ trả lời dựa trên CONTEXT. Nếu không có thông tin, hãy nói rõ là không tìm thấy.';
    final userPrompt = 'CONTEXT:\n$context\n\nCÂU HỎI: $question';

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenAI returned empty choices');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content']?.toString().trim();
    if (content == null || content.isEmpty) {
      throw Exception('OpenAI returned empty content');
    }
    return _sanitizeAiAnswer(content);
  }

  Future<String> _askPremiumOpenAi({
    required String question,
    required String context,
    String? speakerName,
    bool isProactive = false,
  }) async {
    final key = _openAiKey;
    if (key == null || key.isEmpty) {
      throw Exception('Missing OpenAI API key');
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final systemPrompt = InMeetingLogic.buildPremiumSystemPrompt(
      meetingTitle: _meetingTitle,
      hasDocumentContext:
          _contextText != null && _contextText!.trim().isNotEmpty,
    );
    final userPrompt = [
      if (speakerName != null && speakerName.isNotEmpty)
        'Người hỏi: $speakerName',
      if (isProactive)
        'Đây là câu hỏi vừa xuất hiện trong cuộc họp, hãy phản hồi như một agent hỗ trợ trực tiếp.',
      'CONTEXT:\n$context',
      'CÂU HỎI: $question',
    ].join('\n\n');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.45,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenAI returned empty choices');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content']?.toString().trim();
    if (content == null || content.isEmpty) {
      throw Exception('OpenAI returned empty content');
    }
    return _sanitizeAiAnswer(content);
  }

  Future<String> _resolveAiAnswer({
    required String question,
    required String combinedContext,
    required bool allowGeneralKnowledge,
    String? speakerName,
    bool isProactive = false,
  }) async {
    if (_aiEnabled && combinedContext.trim().isNotEmpty) {
      try {
        if (allowGeneralKnowledge) {
          return await _askPremiumOpenAi(
            question: question,
            context: combinedContext,
            speakerName: speakerName,
            isProactive: isProactive,
          );
        }

        return await _askOpenAi(question: question, context: combinedContext);
      } catch (_) {
        return allowGeneralKnowledge
            ? InMeetingLogic.answerPremiumFallback(question, combinedContext)
            : (InMeetingLogic.answerFromContext(question, combinedContext) ??
                "Không thể gọi AI lúc này. Vui lòng thử lại hoặc kiểm tra API key.");
      }
    }

    if (combinedContext.trim().isEmpty) {
      return InMeetingLogic.answerFreely(question);
    }

    final found = InMeetingLogic.answerFromContext(question, combinedContext);
    if (found != null) {
      return found;
    }

    return allowGeneralKnowledge
        ? InMeetingLogic.answerPremiumFallback(question, combinedContext)
        : "Không tìm thấy thông tin trong tài liệu đã tải lên để trả lời câu hỏi này.";
  }

  Future<void> _askAiFromText(String text) async {
    if (_isAskingAi) return;
    setState(() => _isAskingAi = true);

    final combinedContext = InMeetingLogic.buildCombinedContext(
      documentContext: _contextText,
      messages: _messages,
      speakerNames: _speakerNames,
      preferRecentTranscript: _premiumAgentEnabled,
    );
    final answer = await _resolveAiAnswer(
      question: text,
      combinedContext: combinedContext,
      allowGeneralKnowledge: _premiumAgentEnabled,
    );

    final aiMsg = TranscriptMessage(
      speaker: 'AI Agent',
      text: answer,
      isFinal: true,
    );

    if (mounted) {
      setState(() {
        _messages.add(aiMsg);
      });
    }
    _scrollToBottom();
    if (mounted) setState(() => _isAskingAi = false);
  }

  Future<void> _askAiForTranscriptMessage(TranscriptMessage message) async {
    final key = InMeetingLogic.buildMessageKey(message);
    if (_isAskingAi || _premiumHandledMessages.contains(key)) {
      return;
    }

    if (mounted) {
      setState(() {
        _isAskingAi = true;
        _premiumHandledMessages.add(key);
      });
    }

    try {
      final combinedContext = InMeetingLogic.buildCombinedContext(
        documentContext: _contextText,
        messages: _messages,
        speakerNames: _speakerNames,
        preferRecentTranscript: _premiumAgentEnabled,
      );
      final answer = await _resolveAiAnswer(
        question: message.text,
        combinedContext: combinedContext,
        allowGeneralKnowledge: _premiumAgentEnabled,
        speakerName: _speakerNames[message.speaker] ?? message.speaker,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          TranscriptMessage(
            speaker: 'AI Agent',
            text: answer,
            isFinal: true,
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        setState(() {
          _premiumHandledMessages.remove(key);
        });
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isAskingAi = false);
      }
    }
  }

  // ignore: unused_element
  Widget _buildPremiumAgentBanner(ThemeData theme, ColorScheme colorScheme) {
    final thinking = _isPremiumAgentThinking;
    final accent = thinking ? colorScheme.tertiary : colorScheme.primary;
    final title = thinking
        ? 'Premium Agent dang phan tich'
        : 'Premium Agent dang lang nghe';
    final subtitle = thinking
        ? 'Bot dang tong hop transcript va bo canh de dua ra phan hoi phu hop ngay trong cuoc hop.'
        : 'Bot premium co the chu dong ho tro khi phat hien cau hoi kho hoac tinh huong thieu thong tin trong tai lieu.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.16),
            colorScheme.surfaceContainerHighest.withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              thinking ? Icons.auto_awesome : Icons.hearing_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Premium',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  bool _isSummaryTooShort(MeetingSummary summary) {
    final summaryText = summary.summary.trim();
    final hasKeyPoints =
        summary.actionItems.isNotEmpty || summary.keyDecisions.isNotEmpty;
    if (summaryText.isEmpty && !hasKeyPoints) return true;
    if (summaryText.length < 20 && !hasKeyPoints) return true;
    return false;
  }

  Future<void> _discardCurrentMeeting(String sid) async {
    _meetingService.stopStreaming();
    try {
      await _meetingService.deleteMeeting(sid);
    } catch (e) {
      print('Error deleting short meeting: $e');
    }
  }

  Future<void> _confirmExitMeeting() async {
    if (!mounted || _isSummarizing) return;

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc cuộc họp?'),
        content: const Text(
          'Cuộc họp đang diễn ra. Bạn có muốn kết thúc cuộc họp không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục họp'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );

    if (shouldEnd == true) {
      await _handleEndMeeting();
    }
  }

  Future<void> _handleEndMeeting() async {
    if (_isSummarizing) return;

    setState(() => _isSummarizing = true);
    await _pauseRecording();

    final sid = await _meetingService.waitForMeetingSid();
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
      final userId = context.read<AuthProvider>().userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Bạn cần đăng nhập');
      }
      final summary = await SummaryService.summarize(
        sid,
        userId: userId,
      );

      if (InMeetingLogic.isSummaryTooShort(summary)) {
        if (!mounted) return;
        final choice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Nội dung quá ngắn"),
            content: const Text(
                "Nội dung cuộc họp quá ngắn nên không thể tóm tắt. Bạn muốn tiếp tục ghi âm hay kết thúc hẳn cuộc họp này?"),
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

        await _discardCurrentMeeting(sid);
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
              "Cuộc họp có thể quá ngắn hoặc chưa đủ dữ liệu để tóm tắt. Bạn muốn tiếp tục ghi âm hay kết thúc hẳn cuộc họp này?"),
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

      await _discardCurrentMeeting(sid);
      if (mounted) {
        setState(() => _isSummarizing = false);
        context.go('/app/meeting');
      }
    }
  }

  // ignore: unused_element
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

  // ignore: unused_element
  String _answerFreely(String question) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return "Bạn hãy đặt câu hỏi cụ thể hơn nhé.";
    return "Không có tài liệu đính kèm nên mình trả lời tự do theo hiểu biết chung.\n\nCâu hỏi của bạn: $trimmed";
  }

  // ignore: unused_element
  Future<void> _showSpeakerNameDialog(String speakerId) async {
    if (!mounted || _isDialogOpen) return;

    setState(() => _isDialogOpen = true);
    final TextEditingController nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
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

  // ignore: unused_element
  Widget _buildMessage(TranscriptMessage msg, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isAi = msg.speaker == 'AI Agent';
    String displayName = _speakerNames[msg.speaker] ?? msg.speaker;
    String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    // Lấy màu cho speaker
    int speakerIndex = _speakerNames.keys.toList().indexOf(msg.speaker);
    final safeSpeakerIndex = speakerIndex >= 0 ? speakerIndex : 0;
    Color avatarColor =
        _speakerColors[safeSpeakerIndex % _speakerColors.length];
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
            onTap: () async {
              if (_isAskingAi) return;
              await _askAiFromText(msg.text);
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

  Widget _buildStableMeetingScaffold(ThemeData theme, ColorScheme colorScheme) {
    return WillPopScope(
      onWillPop: () async {
        await _confirmExitMeeting();
        return false;
      },
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _meetingTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: _confirmExitMeeting,
        ),
        actions: [
          if (_aiEnabled)
            IconButton(
              tooltip: 'Ask AI',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: _openAskAiSheet,
            ),
          IconButton(
            tooltip: 'End',
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _handleEndMeeting,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _messages.isEmpty
            ? Center(
                child: Text(
                  _isPaused ? 'Paused' : 'Dang lang nghe...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final speaker =
                      _speakerNames[message.speaker] ?? message.speaker;
                  final isAi = message.speaker == 'AI Agent';
                  final showAiPrompt = _shouldShowAiAnswerPrompt(message);
                  final alreadyRequested = !showAiPrompt &&
                      _premiumHandledMessages
                          .contains(InMeetingLogic.buildMessageKey(message));

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isAi
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          speaker,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isAi
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isAi
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (showAiPrompt) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withOpacity(0.72),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Bạn có muốn AI trả lời câu hỏi này không?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: _isAskingAi
                                      ? null
                                      : () async {
                                          try {
                                            await _askAiForTranscriptMessage(
                                                message);
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Không thể gọi AI: $e'),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                  child: Text(
                                      _isAskingAi ? 'Đang trả lời...' : 'Trả lời'),
                                ),
                              ],
                            ),
                          ),
                        ] else if (alreadyRequested && !isAi) ...[
                          const SizedBox(height: 10),
                          Text(
                            'AI đã được gọi cho câu hỏi này.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
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
        child: Icon(
          _isRecording ? (_isPaused ? Icons.play_arrow : Icons.pause) : Icons.mic,
          color: Colors.white,
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _buildStableMeetingScaffold(theme, colorScheme);

    /*
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _meetingTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
            // Recording Status Indicator ở dưới title
          
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
          IconButton(
            tooltip: 'End',
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () async {
              await _handleEndMeeting();
            },
          ),
          // Nút End Meeting (Nút bấm tròn màu đỏ nổi bật)
          if (false) Padding(
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
                return MeetingTranscriptMessage(
                  message: _messages[index],
                  aiEnabled: _aiEnabled,
                  isQuestion: InMeetingLogic.isQuestionText,
                  speakerNames: _speakerNames,
                  speakerColors: _speakerColors,
                  onAskAi: _isAskingAi ? null : _askAiFromText,
                );
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
                          : () async {
                              final q = _chatController.text.trim();
                              if (q.isEmpty) return;
                              _chatController.clear();
                              await _askAiFromText(q);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _aiEnabled ? 88 : 16),
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
    */
  }
}
