import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/features/auth/logic/auth_flow_logic.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_fields.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final l10n = context.l10n;

    if (email.isEmpty || password.isEmpty) {
      AuthFlowLogic.showError(context, l10n.tr('loginEmptyError'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthFlowLogic.loginWithCredentials(
        context: context,
        email: email,
        password: password,
      );
    } catch (e) {
      if (mounted) {
        AuthFlowLogic.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AuthFlowLogic.loginWithGoogle(context);
    } catch (e) {
      if (mounted) {
        AuthFlowLogic.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AuthScreenShell(
      icon: Icons.psychology_alt_rounded,
      title: l10n.tr('loginTitle'),
      subtitle: l10n.tr('loginSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.tr('signIn'), style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _emailController,
            labelText: l10n.tr('emailAddress'),
            hintText: 'name@company.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _passwordController,
            labelText: l10n.tr('password'),
            hintText: l10n.tr('password'),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/reset_password'),
              child: Text(l10n.tr('forgotPassword')),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.tr('logIn')),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _submitGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
            label: Text(l10n.tr('continueWithGoogle')),
          ),
        ],
      ),
      footer: [
        AuthFooterLink(
          label: l10n.tr('loginFooter'),
          onPressed: () => context.go('/register'),
        ),
      ],
    );
  }
}
