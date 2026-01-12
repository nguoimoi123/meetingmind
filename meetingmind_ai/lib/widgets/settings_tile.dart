import 'package:flutter/material.dart';

/// Small settings tile used in Profile/Settings screens.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withOpacity(0.08),
        child: Icon(icon, color: colorScheme.primary),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
    );
  }
}
