import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/models/meeting_summary.dart';

class InMeetingLogic {
  static String _stripDiacritics(String text) {
    const vietnameseMap = {
      'a': 'a',
      'Ã ': 'a',
      'Ã¡': 'a',
      'áº¡': 'a',
      'áº£': 'a',
      'Ã£': 'a',
      'Ã¢': 'a',
      'áº§': 'a',
      'áº¥': 'a',
      'áº­': 'a',
      'áº©': 'a',
      'áº«': 'a',
      'Äƒ': 'a',
      'áº±': 'a',
      'áº¯': 'a',
      'áº·': 'a',
      'áº³': 'a',
      'áºµ': 'a',
      'e': 'e',
      'Ã¨': 'e',
      'Ã©': 'e',
      'áº¹': 'e',
      'áº»': 'e',
      'áº½': 'e',
      'Ãª': 'e',
      'á»': 'e',
      'áº¿': 'e',
      'á»‡': 'e',
      'á»ƒ': 'e',
      'á»…': 'e',
      'i': 'i',
      'Ã¬': 'i',
      'Ã­': 'i',
      'á»‹': 'i',
      'á»‰': 'i',
      'Ä©': 'i',
      'o': 'o',
      'Ã²': 'o',
      'Ã³': 'o',
      'á»': 'o',
      'á»': 'o',
      'Ãµ': 'o',
      'Ã´': 'o',
      'á»“': 'o',
      'á»‘': 'o',
      'á»™': 'o',
      'á»•': 'o',
      'á»—': 'o',
      'Æ¡': 'o',
      'á»': 'o',
      'á»›': 'o',
      'á»£': 'o',
      'á»Ÿ': 'o',
      'á»¡': 'o',
      'u': 'u',
      'Ã¹': 'u',
      'Ãº': 'u',
      'á»¥': 'u',
      'á»§': 'u',
      'Å©': 'u',
      'Æ°': 'u',
      'á»«': 'u',
      'á»©': 'u',
      'á»±': 'u',
      'á»­': 'u',
      'á»¯': 'u',
      'y': 'y',
      'á»³': 'y',
      'Ã½': 'y',
      'á»µ': 'y',
      'á»·': 'y',
      'á»¹': 'y',
      'Ä‘': 'd',
      'A': 'A',
      'Ã€': 'A',
      'Ã': 'A',
      'áº ': 'A',
      'áº¢': 'A',
      'Ãƒ': 'A',
      'Ã‚': 'A',
      'áº¦': 'A',
      'áº¤': 'A',
      'áº¬': 'A',
      'áº¨': 'A',
      'áºª': 'A',
      'Ä‚': 'A',
      'áº°': 'A',
      'áº®': 'A',
      'áº¶': 'A',
      'áº²': 'A',
      'áº´': 'A',
      'E': 'E',
      'Ãˆ': 'E',
      'Ã‰': 'E',
      'áº¸': 'E',
      'áºº': 'E',
      'áº¼': 'E',
      'ÃŠ': 'E',
      'á»€': 'E',
      'áº¾': 'E',
      'á»†': 'E',
      'á»‚': 'E',
      'á»„': 'E',
      'I': 'I',
      'ÃŒ': 'I',
      'Ã': 'I',
      'á»Š': 'I',
      'á»ˆ': 'I',
      'Ä¨': 'I',
      'O': 'O',
      'Ã’': 'O',
      'Ã“': 'O',
      'á»Œ': 'O',
      'á»Ž': 'O',
      'Ã•': 'O',
      'Ã”': 'O',
      'á»’': 'O',
      'á»': 'O',
      'á»˜': 'O',
      'á»”': 'O',
      'á»–': 'O',
      'Æ ': 'O',
      'á»œ': 'O',
      'á»š': 'O',
      'á»¢': 'O',
      'á»ž': 'O',
      'á» ': 'O',
      'U': 'U',
      'Ã™': 'U',
      'Ãš': 'U',
      'á»¤': 'U',
      'á»¦': 'U',
      'Å¨': 'U',
      'Æ¯': 'U',
      'á»ª': 'U',
      'á»¨': 'U',
      'á»°': 'U',
      'á»¬': 'U',
      'á»®': 'U',
      'Y': 'Y',
      'á»²': 'Y',
      'Ã': 'Y',
      'á»´': 'Y',
      'á»¶': 'Y',
      'á»¸': 'Y',
      'Ä': 'D',
    };

    final buffer = StringBuffer();
    for (final char in text.split('')) {
      buffer.write(vietnameseMap[char] ?? char);
    }
    return buffer.toString();
  }

  static String _normalizeForMatch(String text) {
    return _stripDiacritics(text)
        .toLowerCase()
        .replaceAll(RegExp(r"""[.,!?;:()"']"""), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

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
      r'ai|alo|xin hoi|cho hoi|tai sao|vi sao|nhu the nao|lam sao|khi nao|o dau|ai la|co the)\b',
      caseSensitive: false,
    ).hasMatch(_normalizeForMatch(trimmed));
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
        })
        .toList();

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

    return recent
        .map((m) {
          final displayName = speakerNames[m.speaker] ?? m.speaker;
          return '$displayName: ${m.text}';
        })
        .join('\n');
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
        ? 'Uu tien tai lieu dinh kem va transcript cuoc hop lam nguon chinh.'
        : 'Hien khong co tai lieu dinh kem, hay uu tien transcript cuoc hop.';

    return [
      'Ban la Premium Meeting Agent dang tham gia truc tiep trong cuoc hop "$meetingTitle".',
      documentGuidance,
      'Neu cau hoi lien quan den cuoc hop, hay uu tien tra loi dua tren transcript va tai lieu.',
      'Neu cau hoi khong lien quan den cuoc hop, hay tra loi tu nhien theo kien thuc chung.',
      'Neu transcript co thong tin ro rang, hay tra loi truc tiep va ngan gon.',
      'Neu dang suy luan hoac khong chac chan, hay noi ro do la goi y thay vi khang dinh tuyet doi.',
      'Khong bia thong tin nhu the no den tu transcript neu transcript khong thuc su co.',
    ].join(' ');
  }

  static bool shouldPremiumAgentAutoRespond({
    required TranscriptMessage message,
    required bool premiumAgentEnabled,
    required Set<String> handledMessageKeys,
  }) {
    if (!premiumAgentEnabled ||
        !message.isFinal ||
        message.speaker == 'AI Agent') {
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

  static String? _extractPromotionAnswer(String question, String context) {
    final normalizedQuestion = _normalizeForMatch(question);
    final asksAboutPromotion =
        normalizedQuestion.contains('ai') &&
        (normalizedQuestion.contains('len chuc') ||
            normalizedQuestion.contains('lam chuc') ||
            normalizedQuestion.contains('giu chuc') ||
            normalizedQuestion.contains('truong phong'));

    if (!asksAboutPromotion) {
      return null;
    }

    final sentences = context.split(RegExp(r'(?<=[.!?])\s+'));
    for (final sentence in sentences) {
      final trimmedSentence = sentence.trim();
      if (trimmedSentence.isEmpty) {
        continue;
      }

      final normalizedSentence = _normalizeForMatch(trimmedSentence);
      final mentionsPromotion =
          normalizedSentence.contains('len chuc') ||
          normalizedSentence.contains('lam chuc') ||
          normalizedSentence.contains('giu chuc');
      final mentionsManagerRole = normalizedSentence.contains('truong phong');
      if (!mentionsPromotion && !mentionsManagerRole) {
        continue;
      }

      final match = RegExp(
        r'((?:anh|chi|ong|co|ba)?\s*[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)\s+'
        r'(?:len chuc|lam chuc|giu chuc)\s+truong phong',
        caseSensitive: false,
      ).firstMatch(trimmedSentence);

      if (match != null) {
        final promotedPerson = match.group(1)?.trim();
        if (promotedPerson != null && promotedPerson.isNotEmpty) {
          return 'Theo noi dung cuoc hop, $promotedPerson dang lam truong phong.';
        }
      }

      if (mentionsManagerRole) {
        final fallbackMatch = RegExp(
          r'((?:anh|chi|ong|co|ba)?\s*[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)',
          caseSensitive: false,
        ).firstMatch(trimmedSentence);
        final candidateName = fallbackMatch?.group(1)?.trim();
        if (candidateName != null && candidateName.isNotEmpty) {
          return 'Theo noi dung cuoc hop, $candidateName dang lam truong phong.';
        }
      }
    }

    return null;
  }

  static String _normalizeAnswerSentence(String sentence) {
    var normalized = sentence.trim().replaceFirst(RegExp(r'^[\-\s]+'), '');
    if (normalized.isEmpty) {
      return normalized;
    }
    if (!RegExp(r'[.!?]$').hasMatch(normalized)) {
      normalized = '$normalized.';
    }
    return normalized;
  }

  static String? answerFromContext(String question, String context) {
    final normalizedQuestion = _normalizeForMatch(question);
    final normalizedContext = _normalizeForMatch(context);

    if (normalizedQuestion.isEmpty || normalizedContext.isEmpty) {
      return null;
    }

    final promotionAnswer = _extractPromotionAnswer(question, context);
    if (promotionAnswer != null) {
      return promotionAnswer;
    }

    final words = _normalizeForMatch(question)
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .where((w) => !{
              'la',
              'ai',
              'nao',
              'vay',
              'hoi',
              'nay',
              'hom',
              'today',
              'lam',
              'chuc',
            }.contains(w))
        .toSet();

    if (words.isEmpty) {
      return null;
    }

    final sentences = context.split(RegExp(r'(?<=[.!?])\s+'));
    String? bestSentence;
    var bestScore = 0;

    for (final sentence in sentences) {
      final trimmedSentence = sentence.trim();
      if (trimmedSentence.isEmpty) {
        continue;
      }

      final normalizedSentence = _normalizeForMatch(trimmedSentence);
      if (normalizedSentence.endsWith('?')) {
        continue;
      }

      final hitCount = words.where((w) => normalizedSentence.contains(w)).length;
      if (hitCount == 0) {
        continue;
      }

      var score = hitCount;
      if (normalizedSentence.contains('truong phong')) {
        score += 2;
      }
      if (normalizedSentence.contains('len chuc') ||
          normalizedSentence.contains('lam chuc') ||
          normalizedSentence.contains('giu chuc')) {
        score += 2;
      }
      if (RegExp(r'\b(anh|chi|ong|co|ba)\s+[a-z]').hasMatch(normalizedSentence)) {
        score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        bestSentence = trimmedSentence;
      }
    }

    if (bestSentence == null) {
      return null;
    }

    return 'Theo noi dung cuoc hop, ${_normalizeAnswerSentence(bestSentence)}';
  }

  static bool isLikelyMeetingContextQuestion(String text, String context) {
    final normalized = _normalizeForMatch(text);
    if (normalized.isEmpty) {
      return false;
    }

    final meetingSignals = RegExp(
      r'(cuoc hop|meeting|luc nay|vua nay|trong cuoc hop|sep noi|da noi|da chot|'
      r'quyet dinh|action item|deadline|ai len chuc|ai lam|ai phu trach|'
      r'truong phong|thang chuc|len chuc|bao gio trong cuoc hop|hoi nay)',
      caseSensitive: false,
    );
    return meetingSignals.hasMatch(normalized);
  }

  static String answerFreely(String question) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return 'Ban hay dat cau hoi cu the hon nhe.';
    }
    return 'Minh se tra loi tu nhien theo hieu biet chung cho cau hoi: $trimmed';
  }

  static String answerPremiumFallback(String question, String context) {
    final contextAnswer = answerFromContext(question, context);
    if (contextAnswer != null) {
      return contextAnswer;
    }

    return answerFreely(question);
  }
}
