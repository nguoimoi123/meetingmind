import 'package:flutter/material.dart';

class NotebookDetailScreen extends StatelessWidget {
  const NotebookDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marketing Strategy 2024'),
          actions: [
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sources'),
              Tab(text: 'Ask AI'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SourcesTab(),
            AskAITab(),
          ],
        ),
      ),
    );
  }
}

class SourcesTab extends StatelessWidget {
  const SourcesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text('Document ${index + 1}'),
          subtitle:
              Text('Added on: ${DateTime.now().day}/${DateTime.now().month}'),
        );
      },
    );
  }
}

class AskAITab extends StatelessWidget {
  const AskAITab({super.key});

  // Widget helper để tạo một tin nhắn
  Widget _buildMessage(String sender, String text, BuildContext context,
      {required bool isUser}) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(child: Icon(Icons.smart_toy)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? colorScheme.primary : theme.cardColor,
                borderRadius: BorderRadius.circular(12).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: isUser
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
              child: Text(text,
                  style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color)),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150')), // User avatar
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: 16),
              _buildMessage(
                  'AI',
                  'Hi, I\'m your AI assistant. Ask me anything about the documents in this notebook.',
                  context,
                  isUser: false),
              _buildMessage('You',
                  'Summarize the key takeaways from the weekly sync', context,
                  isUser: true),
              _buildMessage(
                  'AI',
                  'The key takeaways from the weekly sync are:\n- Project Alpha is on track.\n- Budget concerns were raised for Q4.\n- The marketing campaign launch is delayed by one week.',
                  context,
                  isUser: false),
            ],
          ),
        ),
        _buildMessageInput(context, colorScheme),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context, ColorScheme colorScheme) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ask AI about this notebook...',
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                suffixIcon:
                    IconButton(icon: const Icon(Icons.mic), onPressed: () {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: colorScheme.primary,
            child: const Icon(Icons.arrow_upward, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
