import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/theme_provider.dart';

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
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.googleUser;

    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Guest User';
    final email = user?.email ?? 'Not signed in';
    final avatarUrl = user?.photoUrl;
    final userId = authProvider.userId;

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
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    backgroundColor: colorScheme.surface,
                    child: avatarUrl == null
                        ? Icon(Icons.person,
                            size: 48, color: colorScheme.onSurface)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (userId != null && userId!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        'ID: $userId',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]
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
                  context.push('/reset_password');
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.credit_card,
                title: 'Manage Subscription',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription settings coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ]),

            // --- Nhóm Tùy chọn Ứng dụng ---
            _buildSettingsGroup([
              ListTile(
                leading: Icon(Icons.contrast, color: colorScheme.primary),
                title: Text('Appearance', style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Dark' : 'Light',
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.language,
                title: 'Language',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language settings coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.calendar_month,
                title: 'Default Calendar',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calendar settings coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help center coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.support_agent,
                title: 'Contact Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support contact coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.policy,
                title: 'Privacy Policy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy policy coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ]),

            // --- Nút Đăng xuất ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
              child: OutlinedButton(
                onPressed: () async {
                  // Gọi AuthProvider để logout
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();

                  // Điều hướng về màn hình Login
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
