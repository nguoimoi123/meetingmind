import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Widget helper để tạo một nhóm các ô cài đặt
  Widget _buildSettingsGroup(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // Widget helper để tạo một ô cài đặt
  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: Icon(Icons.chevron_right,
          color: colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      // AppBar sẽ tự động lấy màu từ theme
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- Phần thông tin người dùng ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const NetworkImage(
                        'https://i.pravatar.cc/150'), // Thay bằng URL avatar thực tế
                    backgroundColor: colorScheme.surface,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'James Anderson',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'james.anderson@meetingmind.ai',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Nhóm Cài đặt Tài khoản ---
            _buildSettingsGroup([
              _buildSettingsTile(
                context: context,
                icon: Icons.lock_reset,
                title: 'Change Password',
                onTap: () {
                  // TODO: Điều hướng đến màn hình đổi mật khẩu
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.credit_card,
                title: 'Manage Subscription',
                onTap: () {
                  // TODO: Điều hướng đến màn hình quản lý đăng ký
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                  // TODO: Điều hướng đến màn hình cài đặt thông báo
                },
              ),
            ]),

            // --- Nhóm Tùy chọn Ứng dụng ---
            _buildSettingsGroup([
              ListTile(
                leading: Icon(Icons.contrast, color: colorScheme.primary),
                title: Text('Appearance', style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  theme.brightness == Brightness.dark ? 'Dark' : 'Light',
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: Switch(
                  value: theme.brightness == Brightness.dark,
                  onChanged: (value) {
                    // TODO: Thêm logic chuyển đổi theme
                    // Cần dùng state management (Provider, Bloc, ...)
                    print('Switch theme to ${value ? 'Dark' : 'Light'}');
                  },
                ),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.language,
                title: 'Language',
                onTap: () {
                  // TODO: Điều hướng đến màn hình chọn ngôn ngữ
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.calendar_month,
                title: 'Default Calendar',
                onTap: () {
                  // TODO: Điều hướng đến màn hình chọn lịch mặc định
                },
              ),
            ]),

            // --- Nhóm Trợ giúp & Hỗ trợ ---
            _buildSettingsGroup([
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline,
                title: 'FAQ & Help Center',
                onTap: () {
                  // TODO: Mở trang web trợ giúp
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.support_agent,
                title: 'Contact Support',
                onTap: () {
                  // TODO: Mở trang web liên hệ hỗ trợ
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.policy,
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Mở trang web chính sách bảo mật
                },
              ),
            ]),

            // --- Nút Đăng xuất ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Logic đăng xuất
                  context.go('/login');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error),
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
