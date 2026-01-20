import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ResetConfirmationScreen extends StatelessWidget {
  const ResetConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy theme và color scheme hiện tại
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        // Dùng Column để căn chỉnh các thành phần
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Căn giữa theo chiều dọc
          children: [
            // --- Icon với nền tròn ---
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1), // Màu nền nhạt
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read,
                size: 64,
                color: AppTheme.successColor, // Màu icon chính
              ),
            ),
            const SizedBox(height: 24),

            // --- Tiêu đề ---
            Text(
              'Email đặt lại mật khẩu đã được gửi!',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // --- Mô tả ---
            Text(
              'Chúng tôi đã gửi một email có chứa liên kết đặt lại mật khẩu đến hòm thư của bạn. Vui lòng kiểm tra thư rác hoặc thư rác nếu bạn không thấy nó.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(), // Đẩy nút xuống dưới cùng
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Quay lại đăng nhập'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
