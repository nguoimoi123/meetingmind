import 'package:flutter/material.dart';

class MeetingSearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSearchTap;

  const MeetingSearchBar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onClear,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      title: Text(
        'My Meetings',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search meetings...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: onClear,
                    )
                  : null,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Search everything',
          icon: const Icon(Icons.travel_explore_rounded),
          onPressed: onSearchTap,
        ),
      ],
    );
  }
}
