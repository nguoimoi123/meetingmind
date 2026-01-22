import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId!;
      final userInfo = await UserService.getUserInfo(userId);
      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Widget helper để tạo một nhóm các ô cài đặt
  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surface, // Sử dụng màu nền của theme
        borderRadius: BorderRadius.circular(16.0),
        // Thêm bóng đổ nhẹ cho thẻ để nổi bật hơn
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Widget helper tạo khung bao quanh icon
  Widget _buildIconWrapper({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(10), // Kích thước padding để tạo vùng vuông vức
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Màu nền đậm hơn 10%
        borderRadius: BorderRadius.circular(12), // Bo tròn góc (Squircle)
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  // Widget helper để tạo một ô cài đặt với Icon đặc sắc
  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color iconColor, // Thêm màu sắc riêng cho icon
    String? subtitle,
    Widget? trailing,
  }) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon đặc sắc
            _buildIconWrapper(icon: icon, color: iconColor),
            const SizedBox(width: 16),
            // Nội dung text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Nút mũi tên hoặc widget khác
            trailing ??
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surfaceContainerLowest, // Màu nền tổng thể nhẹ nhàng
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent, // AppBar trong suốt
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // --- Phần thông tin người dùng ---
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _errorMessage != null
                      ? Column(
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: colorScheme.error),
                            const SizedBox(height: 16),
                            Text('Failed to load user info',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(_errorMessage!,
                                style: theme.textTheme.bodySmall),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: _loadUserInfo,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            // Avatar với viền nhẹ
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage: const NetworkImage(
                                    'https://i.pravatar.cc/150'),
                                backgroundColor: colorScheme.surface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userInfo?['name'] ?? 'Unknown User',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userInfo?['email'] ?? 'No email',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 30),

            // --- Nhóm Cài đặt Tài khoản ---
            _buildSettingsGroup([
              _buildSettingsTile(
                context: context,
                icon: Icons.lock_outline,
                title: 'Change Password',
                iconColor: Colors.blue, // Màu xanh dương
                onTap: () {},
              ),
              // Thêm divider giữa các item trong nhóm (tùy chọn)
              // Padding(padding: EdgeInsets.only(left: 68), child: Divider(height: 1)),
              _buildSettingsTile(
                context: context,
                icon: Icons
                    .workspace_premium, // Icon hình viên kim cương/giấy chứng nhận
                title: 'Manage Subscription',
                iconColor: Colors.purple, // Màu tím sang trọng
                onTap: () {},
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons
                    .notifications_active_outlined, // Icon chuông có dấu active
                title: 'Notifications',
                iconColor: Colors.orange, // Màu cam nổi bật
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 20),

            // --- Nhóm Tùy chọn Ứng dụng ---
            _buildSettingsGroup([
              // Item Appearance tùy chỉnh vì có Switch
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildIconWrapper(
                        icon: Icons.palette_outlined,
                        color: Colors.indigo // Màu chàm
                        ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appearance',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            theme.brightness == Brightness.dark
                                ? 'Dark Mode'
                                : 'Light Mode',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: theme.brightness == Brightness.dark,
                      onChanged: (value) {
                        // TODO: Logic chuyển theme
                        print('Switch theme to ${value ? 'Dark' : 'Light'}');
                      },
                    ),
                  ],
                ),
              ),

              _buildSettingsTile(
                context: context,
                icon: Icons.translate, // Icon dịch thuật
                title: 'Language',
                iconColor: Colors.teal, // Màu xanh ngọc
                onTap: () {},
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.calendar_today_rounded, // Icon lịch bo tròn
                title: 'Default Calendar',
                iconColor: Colors.red, // Màu đỏ
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 20),

            // --- Nhóm Trợ giúp & Hỗ trợ ---
            _buildSettingsGroup([
              _buildSettingsTile(
                context: context,
                icon: Icons.help_center_rounded,
                title: 'FAQ & Help Center',
                iconColor: Colors.cyan,
                onTap: () {},
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.headset_mic_outlined,
                title: 'Contact Support',
                iconColor: Colors.blueGrey,
                onTap: () {},
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.verified_user_outlined,
                title: 'Privacy Policy',
                iconColor: Colors.grey,
                onTap: () {},
              ),
            ]),

            // --- Nút Đăng xuất ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.logout();
                    context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                  label: Text(
                    'Log Out',
                    style: TextStyle(color: colorScheme.error, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
