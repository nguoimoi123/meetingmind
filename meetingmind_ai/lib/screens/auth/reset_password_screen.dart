import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy theme hiện tại để sử dụng
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      // AppBar sẽ tự động lấy màu từ theme
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Sử dụng text style từ theme
            Text(
              'Nhập email của bạn để nhận liên kết đặt lại mật khẩu.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // TextField sẽ tự động có style từ theme
            const TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Nhập email của bạn',
              ),
            ),
            const Spacer(), // Đẩy nút xuống dưới
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/reset_confirmation'),
                child: const Text('Gửi liên kết'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
