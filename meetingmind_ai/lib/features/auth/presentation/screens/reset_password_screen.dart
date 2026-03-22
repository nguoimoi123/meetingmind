import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_fields.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AuthScreenShell(
      icon: Icons.lock_reset_rounded,
      title: l10n.tr('resetPasswordTitle'),
      subtitle: l10n.tr('resetPasswordSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.tr('recoveryEmail'), style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _emailController,
            labelText: l10n.tr('emailAddress'),
            hintText: 'name@company.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: () => context.go('/reset_confirmation'),
            child: Text(l10n.tr('sendResetLink')),
          ),
        ],
      ),
      footer: [
        AuthFooterLink(
          label: l10n.tr('backToLogin'),
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
