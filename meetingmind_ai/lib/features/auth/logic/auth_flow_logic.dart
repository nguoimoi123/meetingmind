import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/auth_service.dart';
import 'package:meetingmind_ai/services/google_auth_service.dart';
import 'package:provider/provider.dart';

class AuthFlowLogic {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> loginWithCredentials({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final data = await AuthService.login(email: email, password: password);

    if (!context.mounted) return;

    await context.read<AuthProvider>().loginWithCredentials(
          userId: data['id']?.toString() ?? '',
          email: data['email']?.toString(),
          name: data['name']?.toString(),
          plan: data['plan']?.toString(),
        );

    if (context.mounted) {
      context.go('/app/home');
    }
  }

  static Future<void> register({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await AuthService.register(
      name: name,
      email: email,
      password: password,
    );

    if (!context.mounted) return;

    await context.read<AuthProvider>().loginWithCredentials(
          userId: data['id']?.toString() ?? '',
          email: data['email']?.toString(),
          name: data['name']?.toString(),
          plan: data['plan']?.toString(),
        );

    if (context.mounted) {
      context.go('/app/home');
    }
  }

  static Future<void> loginWithGoogle(BuildContext context) async {
    final googleAuth = GoogleAuthService();
    final idToken = await googleAuth.loginWithGoogle();

    if (idToken == null || !context.mounted) return;

    final data = await googleAuth.sendTokenToBackend(idToken);
    if (data == null) {
      if (context.mounted) {
        showError(context, 'Google sign in failed');
      }
      return;
    }

    if (!context.mounted) return;

    await context.read<AuthProvider>().loginWithGoogle(
          user: await GoogleSignIn().signInSilently(),
          userIdFromBackend: data['user_id']?.toString() ?? '',
          plan: data['plan']?.toString(),
        );

    if (context.mounted) {
      context.go('/app/home');
    }
  }
}
