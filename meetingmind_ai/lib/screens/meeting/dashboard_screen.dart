import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/widgets/meeting_card.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';

class DashboardScreen extends StatelessWidget {
  final MeetingService _meetingService = MeetingService();

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Welcome back, Maria', style: theme.textTheme.headlineSmall),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: const NetworkImage('https://i.pravatar.cc/150'),
              onBackgroundImageError: (exception, stackTrace) =>
                  const Icon(Icons.person),
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
            Text('Recent Meetings', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            // Sử dụng FutureBuilder để tải dữ liệu
            FutureBuilder<List<Meeting>>(
              future: _meetingService.getPastMeetings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No meetings found.");
                }

                return Column(
                  children: snapshot.data!.map((meeting) {
                    return MeetingCard(
                      title: meeting.title,
                      subtitle: meeting.subtitle,
                      dateLabel: meeting.date,
                      status: meeting.status,
                      onTap: () => context.push('/post_summary'),
                    );
                  }).toList(),
                );
              },
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
