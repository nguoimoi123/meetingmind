import 'package:flutter/material.dart';

class MeetingTagFilters extends StatelessWidget {
  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onSelected;

  const MeetingTagFilters({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: selectedTag == null,
              onSelected: (_) => onSelected(null),
            ),
            ...tags.map(
              (tag) => ChoiceChip(
                label: Text(tag),
                selected: selectedTag == tag,
                onSelected: (_) => onSelected(tag),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
