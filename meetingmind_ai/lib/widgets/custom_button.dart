import 'package:flutter/material.dart';

/// A small, reusable custom button used across the app.
/// Simplified to use ElevatedButton and OutlinedButton from the theme.
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool primary;
  final Widget? leading;
  final bool isLoading;
  final double? width;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = true,
    this.leading,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Chọn kiểu nút dựa trên tham số 'primary'
    if (primary) {
      return SizedBox(
        width: width,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: leading,
          label: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(label),
          style: theme.elevatedButtonTheme.style,
        ),
      );
    } else {
      return SizedBox(
        width: width,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: leading,
          label: Text(label),
          style: theme.outlinedButtonTheme.style,
        ),
      );
    }
  }
}
