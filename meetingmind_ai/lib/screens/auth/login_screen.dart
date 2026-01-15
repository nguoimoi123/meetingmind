import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology,
                      size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Welcome to MeetingMind AI',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Email
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    hintText: 'Enter your email',
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: 'Enter your password',
                    suffixIcon: Icon(Icons.visibility_off),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/reset_password'),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 12),

                // LOGIN — bypass kiểm tra
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // ==============================
                      // TODO: CHECK ACCOUNT LATER HERE
                      // Example:
                      //
                      // final isValid = await authService.login(email, pass);
                      // if (isValid) Navigator.pushReplacementNamed(context, '/app');
                      //
                      // ==============================

                      // Hiện tại: bỏ qua kiểm tra, vào app luôn
                      Provider.of<AuthProvider>(context, listen: false).login();
                      context.go('/app/home');
                    },
                    child: const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 12),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('or', style: theme.textTheme.bodyMedium),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),
                const SizedBox(height: 12),

                // Social Login
                // Social Login
                OutlinedButton.icon(
                  onPressed: () async {
                    final googleAuth = GoogleAuthService();

                    // 1. Lấy ID Token từ Google
                    final idToken = await googleAuth.loginWithGoogle();

                    if (idToken != null) {
                      print("Got ID Token, sending to backend...");

                      // 2. Gửi Token lên Backend để lưu DB
                      final isSuccess =
                          await googleAuth.sendTokenToBackend(idToken);

                      if (isSuccess) {
                        // 3. Nếu lưu thành công -> Login & Chuyển trang
                        Provider.of<AuthProvider>(context, listen: false)
                            .login();
                        context.go('/app/home');
                      } else {
                        // Xử lý khi backend lỗi
                        print("Lỗi khi gửi token lên backend");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Đăng nhập thất bại, không thể lưu dữ liệu.")),
                        );
                      }
                    } else {
                      print("User hủy đăng nhập Google");
                    }
                  },
                  // ... (icon, label giữ nguyên)
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    height: 18,
                    width: 18,
                  ),
                  label: const Text('Continue with Google'),
                ),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Add GitHub OAuth later
                    Navigator.pushReplacementNamed(context, '/app');
                  },
                  icon: Image.network(
                    'https://www.github.com/favicon.ico',
                    height: 18,
                    width: 18,
                  ),
                  label: const Text('Continue with GitHub'),
                ),
                const SizedBox(height: 16),

                // Sign up link
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: const [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
