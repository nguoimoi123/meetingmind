import 'package:flutter/material.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

class NotebookDetailTabBar extends StatelessWidget {
  const NotebookDetailTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: l10n.tr('sources')),
          Tab(text: l10n.tr('askAi')),
          Tab(text: l10n.tr('studio')),
        ],
      ),
    );
  }
}
