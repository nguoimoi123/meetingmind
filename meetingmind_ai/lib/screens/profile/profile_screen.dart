import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/subscription_service.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/theme_provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/services/usage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _limitText(int? limit) => limit == null ? 'Unlimited' : '$limit';

  Future<Map<String, dynamic>?> _getUsage(String userId) async {
    try {
      return await UsageService.getUsage(userId: userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showUpgradeSheet(
    BuildContext context, {
    required String userId,
    required String currentPlan,
  }) async {
    final codeController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> redeem() async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a code')),
                );
                return;
              }

              setState(() => isLoading = true);
              try {
                final plan = await SubscriptionService.redeemCode(
                  userId: userId,
                  code: code,
                );
                await context.read<AuthProvider>().setPlan(plan);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Upgraded to $plan')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              } finally {
                if (context.mounted) {
                  setState(() => isLoading = false);
                }
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 20,
                      right: 20,
                      top: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade Plan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Current: $currentPlan'),
                        const SizedBox(height: 16),
                        _buildPlanCard(
                          context: context,
                          title: 'Free',
                          price: '0₫ / month',
                          showPrice: true,
                          highlighted: currentPlan == 'free',
                          features: const [
                            'Up to 10 meetings/month',
                            '30 minutes per meeting',
                            '5 folders, 5 files each',
                            'Q&A: 30 questions/month',
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPlanCard(
                          context: context,
                          title: 'Plus',
                          price: '99,000₫ / month',
                          showPrice: true,
                          highlighted: currentPlan == 'plus',
                          features: const [
                            'Up to 50 meetings/month',
                            'Up to 4 hours per meeting',
                            '50 folders, 50 files each',
                            'Q&A: 500 questions/month',
                            'Basic AI agent',
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPlanCard(
                          context: context,
                          title: 'Premium',
                          price: '199,000₫ / month',
                          showPrice: true,
                          highlighted: currentPlan == 'premium',
                          features: const [
                            'Unlimited meetings & duration',
                            'Unlimited folders & files',
                            'Unlimited Q&A',
                            'Full AI agent',
                            'In-meeting AI assistant',
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'Enter code to redeem',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : redeem,
                            child: const Text('Redeem Code'),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required List<String> features,
    required bool highlighted,
    String? price,
    bool showPrice = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (showPrice && price != null)
            Text(
              price,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.googleUser;
    final localName = authProvider.name?.trim();
    final localEmail = authProvider.email?.trim();

    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (localName != null && localName.isNotEmpty
            ? localName
            : (authProvider.isLoggedIn ? 'User' : 'Guest User'));
    final email = user?.email ??
        (localEmail?.isNotEmpty == true
            ? localEmail!
            : (authProvider.isLoggedIn ? 'Signed in' : 'Not signed in'));
    final avatarUrl = user?.photoUrl;
    final userId = authProvider.userId;
    final plan = authProvider.plan;
    final limits = authProvider.limits;
    final meetingLimit = PlanLimits.fromLimits(limits, 'meeting_limit');
    final meetingDuration = PlanLimits.meetingDurationMinutesFromLimits(limits);
    final folderLimit = PlanLimits.folderLimitFromLimits(limits);
    final filesPerFolder = PlanLimits.filesPerFolderLimitFromLimits(limits);
    final qaLimit = PlanLimits.qaLimitFromLimits(limits);

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
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: colorScheme.secondary.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Plan: $plan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
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
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan Limits',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text('Meetings/month: ${_limitText(meetingLimit)}'),
                      Text(
                          'Meeting duration: ${_limitText(meetingDuration)} min'),
                      Text('Folders: ${_limitText(folderLimit)}'),
                      Text('Files/folder: ${_limitText(filesPerFolder)}'),
                      const SizedBox(height: 12),
                      if (userId != null && userId!.isNotEmpty)
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _getUsage(userId!),
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            final meetingsRemaining =
                                data?['meetings_remaining'] as int?;
                            final qaRemaining = data?['qa_remaining'] as int?;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (meetingsRemaining != null)
                                  Text(
                                      'Meetings remaining: $meetingsRemaining'),
                                if (meetingsRemaining == null &&
                                    meetingLimit == null)
                                  const Text('Meetings remaining: Unlimited'),
                                if (qaRemaining != null)
                                  Text('Q&A remaining: $qaRemaining'
                                      '${qaLimit != null ? ' / $qaLimit' : ''}'),
                                if (qaRemaining == null && qaLimit == null)
                                  const Text('Q&A remaining: Unlimited'),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Nhóm Cài đặt Tài khoản ---
            _buildSettingsGroup([
              _buildSettingsTile(
                context: context,
                icon: Icons.lock_outline,
                iconColor: Colors.redAccent,
                title: 'Change Password',
                onTap: () {
                  context.push('/reset_password');
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.groups_rounded,
                iconColor: Colors.blue,
                title: 'Team Scheduling',
                onTap: () {
                  context.push('/app/teams');
                },
              ),
              // Thêm divider giữa các item trong nhóm (tùy chọn)
              // Padding(padding: EdgeInsets.only(left: 68), child: Divider(height: 1)),
              _buildSettingsTile(
                context: context,
                icon: Icons
                    .workspace_premium, // Icon hình viên kim cương/giấy chứng nhận
                iconColor: Colors.amber,
                title: 'Manage Subscription',
                onTap: () {
                  if (userId == null || userId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in first'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  _showUpgradeSheet(
                    context,
                    userId: userId!,
                    currentPlan: plan,
                  );
                },
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons
                    .notifications_active_outlined, // Icon chuông có dấu active
                iconColor: Colors.deepOrange,
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

            const SizedBox(height: 20),

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
                icon: Icons.translate, // Icon dịch thuật
                iconColor: Colors.teal,
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
                icon: Icons.calendar_today_rounded, // Icon lịch bo tròn
                iconColor: Colors.deepPurple,
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

            const SizedBox(height: 20),

            // --- Nhóm Trợ giúp & Hỗ trợ ---
            _buildSettingsGroup([
              _buildSettingsTile(
                context: context,
                icon: Icons.help_center_rounded,
                iconColor: Colors.blue,
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
                icon: Icons.headset_mic_outlined,
                iconColor: Colors.orange,
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
                icon: Icons.verified_user_outlined,
                iconColor: Colors.green,
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
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
