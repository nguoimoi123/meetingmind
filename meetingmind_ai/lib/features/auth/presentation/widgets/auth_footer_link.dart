import 'package:flutter/material.dart';

class AuthFooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const AuthFooterLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
