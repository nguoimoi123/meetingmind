import 'package:flutter/material.dart';

Future<bool> showNotebookDeleteDialog(
  BuildContext context, {
  required String name,
}) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete notebook', style: theme.textTheme.titleLarge),
      content: Text(
        'Are you sure you want to delete "$name"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  return confirm ?? false;
}
