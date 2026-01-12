import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hold/generating_summary_screen.dart'; // Import widget loading

class LoginScreen extends StatefulWidget {
  // Chuyển thành StatefulWidget
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // Biến để kiểm tra trạng thái loading

  // Hàm giả lập việc gọi API đăng nhập
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true; // Bắt đầu loading
    });

    // Hiển thị màn hình loading dưới dạng một trang mới
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GeneratingSummaryScreen()),
    );

    // Giả lập API call mất 3 giây
    await Future.delayed(const Duration(seconds: 3));

    // Đóng màn hình loading
    Navigator.of(context).pop();

    // Sau khi xử lý xong, chuyển đến Dashboard
    // TODO: Thêm logic kiểm tra đăng nhập thành công/thất bại
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // ... (phần còn lại của UI giữ nguyên)
            children: [
              const Center(
                  child: Icon(Icons.psychology,
                      size: 80, color: AppTheme.primaryColor)),
              const SizedBox(height: 20),
              Text("Chào mừng đến với MeetingMind AI",
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              const TextField(decoration: InputDecoration(labelText: "Email")),
              const SizedBox(height: 16),
              const TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Mật khẩu")),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Vô hiệu hóa nút và hiển thị loading indicator khi đang tải
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text("Đăng nhập"),
                ),
              ),
              // ... (các nút khác)
            ],
          ),
        ),
      ),
    );
  }
}
