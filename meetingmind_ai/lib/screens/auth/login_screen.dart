import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/services/google_auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Nền tổng thể
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER ĐỘNG (Dynamic Header) ---
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              decoration: BoxDecoration(
                // Gradient hiện đại cho phần trên
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
                  // Logo với hiệu ứng "Glassy"
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Mờ trong suốt
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MeetingMind AI',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Empower your meetings',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. FORM ĐĂNG NHẬP ---
            Transform.translate(
              offset:
                  const Offset(0, -30), // Kéo form lên đè một chút vào header
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tiêu đề nhỏ
                    Center(
                      child: Text(
                        'Welcome Back',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Input
                    _buildModernTextField(
                      context: context,
                      icon: Icons.email_outlined,
                      hintText: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Password Input
                    _buildModernTextField(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      hintText: 'Password',
                      obscureText: true,
                      suffixIcon: Icons.visibility_outlined,
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/reset_password'),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // LOGIN BUTTON (Gradient)
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AuthProvider>().login();
                          context.go('/app/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Log In',
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

            const SizedBox(height: 32),

            // --- 3. SOCIAL LOGIN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Buttons Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          context: context,
                          iconUrl: 'https://www.google.com/favicon.ico',
                          label: 'Google',
                          onTap: () async {
                            final googleAuth = GoogleAuthService();
                            final idToken = await googleAuth.loginWithGoogle();

                            if (idToken != null) {
                              print("Got ID Token, sending to backend...");
                              final userId =
                                  await googleAuth.sendTokenToBackend(idToken);

                              if (userId != null) {
                                Provider.of<AuthProvider>(context,
                                        listen: false)
                                    .loginWithGoogle(
                                  user: await GoogleSignIn().signInSilently(),
                                  userIdFromBackend: userId,
                                );
                                context.go('/app/home');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Đăng nhập thất bại từ backend")),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSocialButton(
                          context: context,
                          iconUrl: 'https://www.github.com/favicon.ico',
                          label: 'GitHub',
                          onTap: () {
                            // TODO: Add GitHub OAuth later
                            Navigator.pushReplacementNamed(context, '/app');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sign up
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/onboarding'),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Input hiện đại
  Widget _buildModernTextField({
    required BuildContext context,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixIcon: Icon(suffixIcon, color: Colors.grey.shade400),
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

  // Helper Widget: Social Button
  Widget _buildSocialButton({
    required BuildContext context,
    required String iconUrl,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: theme.colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(iconUrl, height: 20, width: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
