import 'package:flutter/material.dart';

/// Circular avatar with optional network image, initials fallback and online badge.
class Avatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final String? initials;
  final bool showOnline;
  final Color? borderColor;
  final double borderWidth;

  const Avatar({
    super.key,
    this.radius = 32,
    this.imageUrl,
    this.initials,
    this.showOnline = false,
    this.borderColor,
    this.borderWidth = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final avatar = imageUrl != null && imageUrl!.isNotEmpty
        ? CircleAvatar(radius: radius, backgroundImage: NetworkImage(imageUrl!))
        : CircleAvatar(
            radius: radius,
            backgroundColor: colorScheme.primary.withOpacity(0.12),
            child: Text(
              initials ?? '',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.6,
              ),
            ),
          );

    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        color: borderColor ?? Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          avatar,
          if (showOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.35,
                height: radius * 0.35,
                decoration: BoxDecoration(
                  color: Colors.greenAccent
                      .shade400, // Màu này thường dùng cho trạng thái online
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
