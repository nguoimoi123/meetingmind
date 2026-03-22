import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/providers/locale_provider.dart';
import 'package:meetingmind_ai/providers/theme_provider.dart';
import 'package:meetingmind_ai/services/subscription_service.dart';
import 'package:meetingmind_ai/services/usage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _limitText(BuildContext context, int? limit) {
    return limit == null ? context.l10n.tr('unlimited') : '$limit';
  }

  Future<Map<String, dynamic>?> _getUsage(String userId) async {
    try {
      return await UsageService.getUsage(userId: userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _launchVnpayCheckout(
    BuildContext context, {
    required String userId,
    required String plan,
  }) async {
    try {
      final url = await SubscriptionService.createVnpayCheckoutUrl(
        userId: userId,
        plan: plan,
      );
      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw Exception('Invalid checkout URL');
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        throw Exception('Khong mo duoc VNPAY');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showUpgradeSheet(
    BuildContext context, {
    required String userId,
    required String currentPlan,
  }) async {
    final l10n = context.l10n;
    final codeController = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    final pendingCode = prefs.getString('pending_upgrade_code');
    if (pendingCode != null && pendingCode.isNotEmpty) {
      codeController.text = pendingCode;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> redeem() async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.tr('pleaseEnterCode'))),
                );
                return;
              }

              setState(() => isLoading = true);
              try {
                final plan = await SubscriptionService.redeemCode(
                  userId: userId,
                  code: code,
                );
                await prefs.remove('pending_upgrade_code');
                await prefs.remove('pending_upgrade_plan');
                await context.read<AuthProvider>().setPlan(plan);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.tr('upgradedTo', params: {'plan': plan}),
                      ),
                    ),
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

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.92,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('upgradePlan'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('${l10n.tr('currentPlan')}: $currentPlan'),
                      const SizedBox(height: 16),
                      _buildPlanCard(
                        context: context,
                        title: 'Free',
                        price: '0 / month',
                        highlighted: currentPlan == 'free',
                        features: const [
                          '10 meetings / month',
                          '30 minutes / meeting',
                          '5 folders, 5 files each',
                          '30 Q&A / month',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        context: context,
                        title: 'Plus',
                        price: '99,000 / month',
                        highlighted: currentPlan == 'plus',
                        features: const [
                          '50 meetings / month',
                          '4 hours / meeting',
                          '50 folders, 50 files each',
                          '500 Q&A / month',
                          'Basic AI agent',
                        ],
                        ctaLabel:
                            currentPlan == 'plus' || currentPlan == 'premium'
                                ? null
                                : 'Thanh toan VNPAY',
                        onTap: currentPlan == 'plus' || currentPlan == 'premium'
                            ? null
                            : () => _launchVnpayCheckout(
                                  context,
                                  userId: userId,
                                  plan: 'plus',
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        context: context,
                        title: 'Premium',
                        price: '199,000 / month',
                        highlighted: currentPlan == 'premium',
                        features: const [
                          'Unlimited meetings',
                          'Unlimited folders & files',
                          'Unlimited Q&A',
                          'Full AI agent',
                        ],
                        ctaLabel: currentPlan == 'premium'
                            ? null
                            : 'Thanh toan VNPAY',
                        onTap: currentPlan == 'premium'
                            ? null
                            : () => _launchVnpayCheckout(
                                  context,
                                  userId: userId,
                                  plan: 'premium',
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (pendingCode != null && pendingCode.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Admin da gui san code nang cap cho tai khoan nay. Ban co the redeem ngay ben duoi.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: l10n.tr('enterCode'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : redeem,
                          child: Text(l10n.tr('redeemCode')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final localeProvider = context.read<LocaleProvider>();
    final l10n = context.l10n;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('languageSheetTitle'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language),
                  title: Text(l10n.tr('languageVietnamese')),
                  trailing: localeProvider.locale.languageCode == 'vi'
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () async {
                    await localeProvider.setLocale(const Locale('vi'));
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(l10n.tr('languageEnglish')),
                  trailing: localeProvider.locale.languageCode == 'en'
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () async {
                    await localeProvider.setLocale(const Locale('en'));
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required List<String> features,
    required bool highlighted,
    String? ctaLabel,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surfaceContainerLowest,
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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            price,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          ...features.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
          if (ctaLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                child: Text(ctaLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = authProvider.googleUser;
    final localName = authProvider.name?.trim();
    final localEmail = authProvider.email?.trim();

    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (localName != null && localName.isNotEmpty
            ? localName
            : (authProvider.isLoggedIn
                ? l10n.tr('user')
                : l10n.tr('guestUser')));
    final email = user?.email ??
        (localEmail?.isNotEmpty == true
            ? localEmail!
            : (authProvider.isLoggedIn
                ? l10n.tr('signedIn')
                : l10n.tr('notSignedIn')));
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
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.tr('profileTitle')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 48,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              backgroundColor: colorScheme.surface,
              child: avatarUrl == null
                  ? Icon(Icons.person_rounded,
                      size: 44, color: colorScheme.onSurface)
                  : null,
            ),
            const SizedBox(height: 14),
            Text(displayName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(label: Text('${l10n.tr('plan')}: $plan')),
                if (userId != null && userId.isNotEmpty)
                  Chip(label: Text('${l10n.tr('id')}: $userId')),
              ],
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('planLimits'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.tr('meetingsPerMonth')}: ${_limitText(context, meetingLimit)}',
                      ),
                      Text(
                        '${l10n.tr('meetingDuration')}: ${_limitText(context, meetingDuration)} min',
                      ),
                      Text(
                        '${l10n.tr('folders')}: ${_limitText(context, folderLimit)}',
                      ),
                      Text(
                        '${l10n.tr('filesPerFolder')}: ${_limitText(context, filesPerFolder)}',
                      ),
                      const SizedBox(height: 12),
                      if (userId != null && userId.isNotEmpty)
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _getUsage(userId),
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            final meetingsRemaining =
                                data?['meetings_remaining'] as int?;
                            final qaRemaining = data?['qa_remaining'] as int?;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l10n.tr('meetingsRemaining')}: ${meetingsRemaining?.toString() ?? _limitText(context, null)}',
                                ),
                                Text(
                                  '${l10n.tr('qaRemaining')}: ${qaRemaining?.toString() ?? l10n.tr('unlimited')}${qaRemaining != null && qaLimit != null ? ' / $qaLimit' : ''}',
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSectionCard(
              context,
              [
                _buildTile(
                  context: context,
                  icon: Icons.lock_outline_rounded,
                  title: l10n.tr('changePassword'),
                  onTap: () => context.push('/reset_password'),
                ),
                _buildTile(
                  context: context,
                  icon: Icons.groups_rounded,
                  title: l10n.tr('teamScheduling'),
                  onTap: () => context.push('/app/teams'),
                ),
                _buildTile(
                  context: context,
                  icon: Icons.workspace_premium_rounded,
                  title: l10n.tr('manageSubscription'),
                  onTap: () {
                    if (userId == null || userId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.tr('pleaseLoginFirst')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    _showUpgradeSheet(
                      context,
                      userId: userId,
                      currentPlan: plan,
                    );
                  },
                ),
              ],
            ),
            _buildSectionCard(
              context,
              [
                _buildTile(
                  context: context,
                  icon: Icons.contrast_rounded,
                  title: l10n.tr('appearance'),
                  subtitle: themeProvider.isDarkMode
                      ? l10n.tr('dark')
                      : l10n.tr('light'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                  onTap: () => themeProvider.toggleTheme(),
                ),
                _buildTile(
                  context: context,
                  icon: Icons.translate_rounded,
                  title: l10n.tr('language'),
                  subtitle: localeProvider.locale.languageCode == 'vi'
                      ? l10n.tr('languageVietnamese')
                      : l10n.tr('languageEnglish'),
                  onTap: () => _showLanguageSheet(context),
                ),
              ],
            ),
            _buildSectionCard(
              context,
              [
                _buildTile(
                  context: context,
                  icon: Icons.notifications_active_outlined,
                  title: l10n.tr('notifications'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.tr('comingSoonNotifications')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildTile(
                  context: context,
                  icon: Icons.calendar_today_rounded,
                  title: l10n.tr('defaultCalendar'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.tr('comingSoonCalendar')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildTile(
                  context: context,
                  icon: Icons.help_center_rounded,
                  title: l10n.tr('faqHelp'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.tr('comingSoonHelp')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildTile(
                  context: context,
                  icon: Icons.headset_mic_outlined,
                  title: l10n.tr('contactSupport'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.tr('comingSoonSupport')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildTile(
                  context: context,
                  icon: Icons.verified_user_outlined,
                  title: l10n.tr('privacyPolicy'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.tr('comingSoonPrivacy')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: OutlinedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error),
                  foregroundColor: theme.colorScheme.error,
                ),
                child: Text(l10n.tr('logout')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
