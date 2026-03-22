import 'package:flutter/material.dart';

class CreateNotebookForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final FocusNode titleFocusNode;
  final FocusNode descriptionFocusNode;
  final bool isLoading;

  const CreateNotebookForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.titleFocusNode,
    required this.descriptionFocusNode,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Name',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: titleController,
            focusNode: titleFocusNode,
            enabled: !isLoading,
            textCapitalization: TextCapitalization.words,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Q4 Marketing Plan',
              fillColor: isDark
                  ? colorScheme.surface
                  : theme.scaffoldBackgroundColor,
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Description (Optional)',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descriptionController,
            focusNode: descriptionFocusNode,
            enabled: !isLoading,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Briefly describe this project...',
              fillColor: isDark
                  ? colorScheme.surface
                  : theme.scaffoldBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
