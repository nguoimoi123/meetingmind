import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotebookListScreen extends StatelessWidget {
  const NotebookListScreen({super.key});

  Widget _buildNotebookCard(
      BuildContext context, String title, int sourceCount, IconData icon) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.push('/notebook_detail'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 40,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$sourceCount Sources',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Notebooks', style: theme.textTheme.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildNotebookCard(
              context, 'Marketing Strategy 2024', 5, Icons.folder),
          _buildNotebookCard(context, 'Q3 Financials', 12, Icons.assessment),
          _buildNotebookCard(
              context, 'Project Phoenix', 8, Icons.rocket_launch),
          _buildNotebookCard(
              context, 'Client Onboarding', 1, Icons.description),
          _buildNotebookCard(context, 'Team Sync Notes', 22, Icons.group),
          _buildNotebookCard(context, 'Product Ideas', 3, Icons.lightbulb),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notebook_detail'),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
