import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/empty_state.dart'; // Giả sử bạn có widget này

class EmptyStateNotebooksScreen extends StatelessWidget {
  const EmptyStateNotebooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Notebooks', style: theme.textTheme.headlineSmall),
      ),
      body: EmptyState(
        icon: Icons.library_books,
        title: 'You have no notebooks.',
        subtitle: 'Create your first notebook to organize notes and documents.',
        actionLabel: 'Create New Notebook',
        onAction: () => context.push('/notebook_detail'),
      ),
      // BottomNavigationBar được thêm vào để nhất quán
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Màn hình hiện tại là Notebook
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Notebooks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        onTap: (index) {
          // TODO: Điều hướng đến các trang khác
          if (index == 0) Navigator.pushReplacementNamed(context, '/app');
        },
      ),
    );
  }
}
