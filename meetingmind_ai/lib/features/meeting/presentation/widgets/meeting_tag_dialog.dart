import 'package:flutter/material.dart';

Future<List<String>?> showMeetingTagDialog(
  BuildContext context, {
  required List<String> initialTags,
}) async {
  final controller = TextEditingController(text: initialTags.join(', '));

  final result = await showDialog<List<String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit tags'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'tag1, tag2, tag3',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final tags = controller.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            Navigator.pop(context, tags);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}
