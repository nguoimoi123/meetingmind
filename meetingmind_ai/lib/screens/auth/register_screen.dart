import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.30,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                    colorScheme.secondary.withOpacity(0.5),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildModernTextField(
                      context: context,
                      icon: Icons.person_outline,
                      hintText: 'Full Name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      context: context,
                      icon: Icons.email_outlined,
                      hintText: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Password',
                      obscureText: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Confirm Password',
                      obscureText: true,
                      controller: _confirmController,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final name = _nameController.text.trim();
                                final email = _emailController.text.trim();
                                final password =
                                    _passwordController.text.trim();
                                final confirm = _confirmController.text.trim();

                                if (name.isEmpty ||
                                    email.isEmpty ||
                                    password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please fill all required fields'),
                                    ),
                                  );
                                  return;
                                }

                                if (password != confirm) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match'),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isLoading = true);
                                try {
                                  final data = await AuthService.register(
                                    name: name,
                                    email: email,
                                    password: password,
                                  );

                                  await context
                                      .read<AuthProvider>()
                                      .loginWithCredentials(
                                        userId: data['id']?.toString() ?? '',
                                        email: data['email']?.toString(),
                                        name: data['name']?.toString(),
                                        plan: data['plan']?.toString(),
                                      );

                                  if (mounted) {
                                    context.go('/app/home');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Log In',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required BuildContext context,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextEditingController? controller,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
