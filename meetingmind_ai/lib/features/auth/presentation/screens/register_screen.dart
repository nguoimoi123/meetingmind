import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/features/auth/logic/auth_flow_logic.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_fields.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:meetingmind_ai/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final l10n = context.l10n;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      AuthFlowLogic.showError(context, l10n.tr('registerRequiredError'));
      return;
    }

    if (password != confirm) {
      AuthFlowLogic.showError(context, l10n.tr('passwordMismatchError'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthFlowLogic.register(
        context: context,
        name: name,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AuthScreenShell(
      icon: Icons.person_add_alt_1_rounded,
      title: l10n.tr('registerTitle'),
      subtitle: l10n.tr('registerSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.tr('getStarted'), style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _nameController,
            labelText: l10n.tr('fullName'),
            hintText: l10n.tr('displayNameHint'),
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
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
            hintText: l10n.tr('createPassword'),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _confirmController,
            labelText: l10n.tr('confirmPassword'),
            hintText: l10n.tr('reenterPassword'),
            icon: Icons.verified_user_outlined,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
          const SizedBox(height: 22),
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
                : Text(l10n.tr('createAccount')),
          ),
        ],
      ),
      footer: [
        AuthFooterLink(
          label: l10n.tr('registerFooter'),
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
