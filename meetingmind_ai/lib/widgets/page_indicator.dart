import 'package:flutter/material.dart';

/// Simple page indicator (dots) used in onboarding pages.
class PageIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final double size;
  final double spacing;

  const PageIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
    this.size = 8.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : spacing),
          height: size,
          width: isActive ? size * 3 : size,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(size / 2),
          ),
        );
      }),
    );
  }
}
