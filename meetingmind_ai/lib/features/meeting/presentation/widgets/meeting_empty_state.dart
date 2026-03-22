import 'package:flutter/material.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

class MeetingEmptyState extends StatelessWidget {
  const MeetingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_off_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('noMeetingsFound'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
