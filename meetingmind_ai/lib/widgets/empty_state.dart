import 'package:flutter/material.dart';
import 'custom_button.dart';

/// Generic empty state widget with icon, texts and a primary action.
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final double iconSize;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    this.iconSize = 80,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget displayedIcon = iconWidget ??
        Icon(
          icon ?? Icons.info_outline,
          size: iconSize,
          color: colorScheme.primary.withOpacity(0.8),
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            displayedIcon,
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                onPressed: onAction!,
                label: actionLabel!,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
