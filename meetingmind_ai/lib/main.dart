import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

// Theme
import 'theme/app_theme.dart';

// Screens
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/reset_confirmation_screen.dart';

import 'screens/app_shell.dart';

import 'screens/meeting/dashboard_screen.dart';
import 'screens/notebook/notebook_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/schedule/schedule_tasks_screen.dart';

import 'screens/meeting/in_meeting_screen.dart';
import 'screens/meeting/post_meeting_summary_screen.dart';
import 'screens/notebook/notebook_detail_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final router = GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/splash',

      /// Theo dõi trạng thái auth để redirect đúng cách
      refreshListenable: auth,

      redirect: (context, state) {
        final bool loggedIn = auth.isLoggedIn;
        final bool goingToAuth = state.uri.path.startsWith('/login') ||
            state.uri.path == '/onboarding' ||
            state.uri.path == '/splash';

        // Chưa login → chỉ cho vào splash, onboarding, login
        if (!loggedIn && !goingToAuth) {
          return '/splash';
        }

        // ✔ Đã login → không vào lại /login
        if (loggedIn && goingToAuth) {
          return '/app/home';
        }

        return null;
      },

      routes: [
        /// PUBLIC ROUTES
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),

        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),

        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),

        GoRoute(
          path: '/reset_password',
          builder: (_, __) => const ResetPasswordScreen(),
        ),

        GoRoute(
          path: '/reset_confirmation',
          builder: (_, __) => const ResetConfirmationScreen(),
        ),

        /// APP SHELL
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/app/home',
              builder: (_, __) => DashboardScreen(),
            ),
            GoRoute(
              path: '/app/notebooks',
              builder: (_, __) => const NotebookListScreen(),
            ),
            GoRoute(
              path: '/app/calendar',
              builder: (_, __) => const ScheduleTasksScreen(),
            ),
            GoRoute(
              path: '/app/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),

        /// OTHER ROUTES OUTSIDE SHELL
        GoRoute(
          path: '/in_meeting',
          builder: (_, __) => const InMeetingScreen(),
        ),

        GoRoute(
          path: '/post_summary/:sid',
          builder: (context, state) {
            final sid = state.pathParameters['sid']!;
            return PostMeetingSummaryScreen(
              meetingSid: sid,
              transcripts: [],
            );
          },
        ),
        GoRoute(
          path: '/notebook_detail',
          builder: (_, __) => const NotebookDetailScreen(),
        ),
      ],
    );

    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        return MaterialApp.router(
          title: 'MeetingMind AI',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
