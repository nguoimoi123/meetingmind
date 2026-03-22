import 'package:flutter/material.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

Future<void> showDashboardAgendaSheet(
  BuildContext context, {
  required Map<String, dynamic> data,
}) async {
  final l10n = context.l10n;
  final agendaItems = (data['agenda_items'] as List?) ?? [];
  final goals = (data['goals'] as List?) ?? [];
  final risks = (data['risks'] as List?) ?? [];
  final followUps = (data['follow_ups'] as List?) ?? [];

  Widget buildList(String title, List items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.toString())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('aiAgendaSuggestions'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                buildList(l10n.tr('agendaItems'), agendaItems),
                buildList(l10n.tr('goals'), goals),
                buildList(l10n.tr('risks'), risks),
                buildList(l10n.tr('followUps'), followUps),
              ],
            ),
          ),
        ),
      );
    },
  );
}
