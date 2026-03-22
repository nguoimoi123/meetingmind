import 'package:flutter/material.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';

class MeetingTranscriptMessage extends StatelessWidget {
  final TranscriptMessage message;
  final bool aiEnabled;
  final bool Function(String text) isQuestion;
  final Map<String, String> speakerNames;
  final List<Color> speakerColors;
  final Future<void> Function(String text)? onAskAi;

  const MeetingTranscriptMessage({
    super.key,
    required this.message,
    required this.aiEnabled,
    required this.isQuestion,
    required this.speakerNames,
    required this.speakerColors,
    this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAi = message.speaker == 'AI Agent';
    final displayName = speakerNames[message.speaker] ?? message.speaker;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final speakerIndex = speakerNames.keys.toList().indexOf(message.speaker);
    final avatarColor = speakerColors[speakerIndex % speakerColors.length];
    final isQuestionBubble = aiEnabled && !isAi && isQuestion(message.text);

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
            message.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color:
                  isAi ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              height: 1.5,
              fontWeight: message.isFinal ? FontWeight.w400 : FontWeight.w300,
              fontStyle: message.isFinal ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          if (isQuestionBubble) ...[
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

    final bubbleWrapper = isQuestionBubble && onAskAi != null
        ? InkWell(
            onTap: () => onAskAi!(message.text),
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
                    fontWeight: FontWeight.bold,
                  ),
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
}
