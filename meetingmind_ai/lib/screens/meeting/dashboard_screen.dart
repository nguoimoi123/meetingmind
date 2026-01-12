import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/meeting_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome back, Maria',
          style: theme.textTheme.headlineSmall,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: const NetworkImage('https://i.pravatar.cc/150'),
              onBackgroundImageError: (exception, stackTrace) {
                const Icon(Icons.person);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Recent Meetings',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            MeetingCard(
              title: 'Q4 Marketing Strategy',
              subtitle: '3 action items, 1 key decision',
              dateLabel: 'Oct 26, 2023, 10:00 AM',
              status: 'Completed',
              onTap: () => context.push('/post_summary'),
            ),
            MeetingCard(
              title: 'Project Phoenix Sync',
              subtitle: '5 action items, 2 key decisions',
              dateLabel: 'Oct 25, 2023, 2:00 PM',
              status: 'In Progress',
              onTap: () => context.push('/post_summary'),
            ),
            MeetingCard(
              title: 'Weekly Team Stand-up',
              subtitle: '1 action item, 0 key decisions',
              dateLabel: 'Oct 24, 2023, 11:30 AM',
              status: 'Completed',
              onTap: () => context.push('/post_summary'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/in_meeting'),
        icon: const Icon(Icons.add),
        label: const Text('New Meeting'),
        backgroundColor: colorScheme.secondary,
      ),
    );
  }
}
