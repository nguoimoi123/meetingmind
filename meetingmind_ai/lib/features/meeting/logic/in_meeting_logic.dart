import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/models/meeting_summary.dart';

class InMeetingLogic {
  static bool isQuestionText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    if (trimmed.contains('?')) {
      return true;
    }

    return RegExp(
      r'^(who|what|when|where|why|how|which|can|could|should|would|do|does|did|is|are|am|will|'
      r'ai|alo|xin hỏi|cho hỏi|tại sao|vì sao|như thế nào|làm sao|khi nào|ở đâu|ai là|có thể)\b',
      caseSensitive: false,
    ).hasMatch(trimmed);
  }

  static bool isPremiumInMeetingAgentEnabled({
    required bool aiAgentEnabled,
    required String plan,
    required Map<String, dynamic> limits,
  }) {
    if (!aiAgentEnabled) {
      return false;
    }

    return PlanLimits.inMeetingAiAllowedFromLimits(limits) ||
        PlanLimits.inMeetingAiAllowed(plan);
  }

  static String buildTranscriptContext(
    List<TranscriptMessage> messages,
    Map<String, String> speakerNames,
  ) {
    final lines = messages
        .where((m) => m.isFinal && m.speaker != 'AI Agent')
        .map((m) {
      final displayName = speakerNames[m.speaker] ?? m.speaker;
      return '$displayName: ${m.text}';
    }).toList();

    return lines.join('\n');
  }

  static String buildRecentTranscriptContext(
    List<TranscriptMessage> messages,
    Map<String, String> speakerNames, {
    int maxMessages = 18,
  }) {
    final filtered = messages
        .where((m) => m.isFinal && m.speaker != 'AI Agent')
        .toList(growable: false);

    final recent = filtered.length <= maxMessages
        ? filtered
        : filtered.sublist(filtered.length - maxMessages);

    return recent.map((m) {
      final displayName = speakerNames[m.speaker] ?? m.speaker;
      return '$displayName: ${m.text}';
    }).join('\n');
  }

  static String buildCombinedContext({
    String? documentContext,
    required List<TranscriptMessage> messages,
    required Map<String, String> speakerNames,
    bool preferRecentTranscript = false,
  }) {
    final transcript = preferRecentTranscript
        ? buildRecentTranscriptContext(messages, speakerNames)
        : buildTranscriptContext(messages, speakerNames);

    return [
      if (documentContext != null && documentContext.trim().isNotEmpty)
        truncateContext(documentContext.trim(), maxChars: 7000),
      if (transcript.trim().isNotEmpty)
        truncateContext(transcript.trim(), maxChars: 8000),
    ].join('\n\n');
  }

  static String truncateContext(String text, {int maxChars = 12000}) {
    if (text.length <= maxChars) {
      return text;
    }

    return text.substring(text.length - maxChars);
  }

  static String buildPremiumSystemPrompt({
    required String meetingTitle,
    required bool hasDocumentContext,
  }) {
    final documentGuidance = hasDocumentContext
        ? 'Ưu tiên tài liệu đính kèm và transcript cuộc họp làm nguồn chính.'
        : 'Hiện không có tài liệu đính kèm, hãy ưu tiên transcript cuộc họp.';

    return [
      'Bạn là Premium Meeting Agent đang tham gia trực tiếp trong cuộc họp "$meetingTitle".',
      documentGuidance,
      'Nhiệm vụ của bạn là hỗ trợ người dùng ngay trong tình huống thực tế, không trả lời rập khuôn.',
      'Nếu transcript/tài liệu đủ dữ liệu thì trả lời chắc chắn, ngắn gọn, hành động được.',
      'Nếu transcript/tài liệu không đủ, bạn được phép dùng kiến thức chung để giúp người dùng bớt bối rối.',
      'Khi dùng kiến thức chung hoặc suy luận, hãy nói rõ đó là "gợi ý" hoặc "suy luận" thay vì khẳng định tuyệt đối.',
      'Nếu câu hỏi mơ hồ, hãy đưa ra câu trả lời tốt nhất trước, rồi gợi ý 1 câu hỏi làm rõ ngắn nếu cần.',
      'Ưu tiên phong cách tự nhiên như một đồng đội trong cuộc họp: rõ, ngắn, hữu ích, đúng tình huống.',
      'Không bịa số liệu hay trích dẫn tài liệu không tồn tại trong context.',
    ].join(' ');
  }

  static bool shouldPremiumAgentAutoRespond({
    required TranscriptMessage message,
    required bool premiumAgentEnabled,
    required Set<String> handledMessageKeys,
  }) {
    if (!premiumAgentEnabled || !message.isFinal || message.speaker == 'AI Agent') {
      return false;
    }

    if (!isQuestionText(message.text)) {
      return false;
    }

    final key = buildMessageKey(message);
    return !handledMessageKeys.contains(key);
  }

  static String buildMessageKey(TranscriptMessage message) {
    return '${message.speaker}|${message.text.trim()}';
  }

  static bool isSummaryTooShort(MeetingSummary summary) {
    final summaryText = summary.summary.trim();
    final hasKeyPoints =
        summary.actionItems.isNotEmpty || summary.keyDecisions.isNotEmpty;
    if (summaryText.isEmpty && !hasKeyPoints) return true;
    if (summaryText.length < 20 && !hasKeyPoints) return true;
    return false;
  }

  static String? answerFromContext(String question, String context) {
    final words = question
        .replaceAll(RegExp(r'[^a-zA-Z0-9À-ỹ\s]'), ' ')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();

    if (words.isEmpty) {
      return null;
    }

    final sentences = context.split(RegExp(r'(?<=[.!?])\s+'));
    final matches = <String>[];
    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      final hit = words.any((w) => lower.contains(w));
      if (hit) {
        matches.add(sentence.trim());
      }
      if (matches.length >= 2) {
        break;
      }
    }

    if (matches.isEmpty) {
      return null;
    }

    return 'Dựa trên nội dung cuộc họp/tài liệu:\n- ${matches.join("\n- ")}';
  }

  static String answerFreely(String question) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return 'Bạn hãy đặt câu hỏi cụ thể hơn nhé.';
    }
    return 'Hiện chưa có đủ ngữ cảnh cuộc họp/tài liệu nên mình trả lời theo hiểu biết chung.\n\nCâu hỏi của bạn: $trimmed';
  }

  static String answerPremiumFallback(String question, String context) {
    final contextAnswer = answerFromContext(question, context);
    if (contextAnswer != null) {
      return contextAnswer;
    }

    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return 'Mình chưa nghe rõ câu hỏi. Bạn có thể nói lại ngắn gọn hơn không?';
    }

    return [
      'Mình chưa thấy câu trả lời rõ ràng trong transcript hoặc tài liệu.',
      'Gợi ý nhanh: hãy xác nhận lại mục tiêu câu hỏi, người chịu trách nhiệm và mốc thời gian liên quan để tránh bị rối ngay trong cuộc họp.',
      'Nếu bạn muốn, mình có thể giúp bạn soạn một câu hỏi làm rõ ngắn để hỏi lại cả nhóm.',
    ].join('\n\n');
  }
}
