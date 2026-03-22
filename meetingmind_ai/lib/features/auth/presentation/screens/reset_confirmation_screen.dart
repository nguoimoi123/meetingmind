import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';
import 'package:meetingmind_ai/theme/app_theme.dart';

class ResetConfirmationScreen extends StatelessWidget {
  const ResetConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AuthScreenShell(
      icon: Icons.mark_email_read_outlined,
      title: l10n.tr('checkInbox'),
      subtitle: l10n.tr('checkInboxSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.successColor,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.tr('passwordResetEmailSent'),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr('passwordResetInstruction'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.tr('backToLogin')),
          ),
        ],
      ),
    );
  }
}
