import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/empty_state.dart'; // Giả sử bạn có widget này

class EmptyStateMeetingsScreen extends StatelessWidget {
  const EmptyStateMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recent Meetings',
          style: theme.textTheme.headlineSmall,
        ),
      ),
      body: EmptyState(
        icon: Icons.calendar_month,
        title: 'No meetings recorded',
        subtitle:
            'Start your first meeting to see summaries and insights here.',
        actionLabel: 'Start a new meeting now!',
        onAction: () => context.push('/in_meeting'),
      ),
    );
  }
}
