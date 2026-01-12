import 'package:flutter/material.dart';

class PostMeetingSummaryScreen extends StatelessWidget {
  const PostMeetingSummaryScreen({super.key});

  // Widget helper để tạo các ô mở rộng
  Widget _buildExpansionTile(
      BuildContext context, String title, String content, IconData icon) {
    final ThemeData theme = Theme.of(context);

    return ExpansionTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meeting Summary',
          style: theme.textTheme.headlineSmall,
        ),
      ),
      body: Column(
        children: [
          // Phần tiêu đề cuộc họp
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q4 Product Strategy Review',
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  'Dec 15, 2023 ・ 10:00 AM',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Danh sách các phần nội dung
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildExpansionTile(
                  context,
                  'Summary',
                  'This meeting covered the Q4 product strategy, focusing on the new marketing campaign budget, which was approved. Key discussion points included the timeline for the next feature launch, which has been postponed to Q1 2024.',
                  Icons.description,
                ),
                _buildExpansionTile(
                  context,
                  'Action Items',
                  '1. Finalize Q4 budget (Assignee: Alex, Due: Dec 20)\n2. Draft user survey for new feature feedback (Assignee: Sam, Due: Dec 22)',
                  Icons.task_alt,
                ),
                _buildExpansionTile(
                  context,
                  'Key Decisions',
                  '1. Approved the new marketing campaign budget.\n2. Postponed the feature launch to Q1 2024.',
                  Icons.lightbulb,
                ),
                _buildExpansionTile(
                  context,
                  'Full Transcript',
                  'A complete, word-for-word record of the meeting is available for review.',
                  Icons.forum,
                ),
              ],
            ),
          ),
        ],
      ),
      // Thanh nút ở dưới cùng
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Logic chia sẻ
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Summary'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Logic thêm vào lịch
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Add to Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
