import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showUpgradeDialog(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Upgrade Required'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.go('/app/profile');
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
}
