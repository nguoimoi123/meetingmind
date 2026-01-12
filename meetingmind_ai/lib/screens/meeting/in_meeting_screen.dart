import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InMeetingScreen extends StatelessWidget {
  const InMeetingScreen({super.key});

  // Widget helper để tạo một tin nhắn
  Widget _buildMessage(String speaker, String text, BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Xác định màu cho avatar dựa trên người nói
    Color avatarColor =
        speaker == 'Speaker 1' ? Colors.blue[100]! : Colors.purple[100]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: avatarColor,
            child: Text(
              speaker.substring(speaker.length - 1), // Lấy số cuối cùng
              style: TextStyle(
                  color: avatarColor == Colors.blue[100]
                      ? Colors.blue[800]
                      : Colors.purple[800],
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Q3 Project Planning'),
        actions: [
          // Nút Tạm dừng
          TextButton.icon(
            onPressed: () {
              // TODO: Logic tạm dừng
            },
            icon: const Icon(Icons.pause_circle),
            label: const Text('Pause'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.secondary,
            ),
          ),
          // Nút Kết thúc
          TextButton.icon(
            onPressed: () {
              context.pushReplacement('/post_summary');
            },
            icon: const Icon(Icons.stop_circle),
            label: const Text('End'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.secondary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh trạng thái ghi âm
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: colorScheme.primary,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recording...',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          // Khu vực hiển thị bản ghi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildMessage(
                    'Speaker 1',
                    "Let's start by reviewing the milestones from last quarter.",
                    context),
                _buildMessage(
                    'Speaker 2',
                    'Agreed. I have the data pulled up and ready to share.',
                    context),
                _buildMessage(
                    'Speaker 1',
                    'Perfect. What are the key takeaways from the Q2 performance metrics?',
                    context),
                _buildMessage(
                    'Speaker 2',
                    'Our user engagement is up by 15%, which is fantastic. However, the conversion rate on the new feature is slightly below our target.',
                    context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Logic lệnh thoại
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Voice command feature coming soon!")),
          );
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }
}
