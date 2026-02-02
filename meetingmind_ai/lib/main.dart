import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- THÊM IMPORT NÀY ĐỂ SỬA LỖI GIỜ THÔNG BÁO ---
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// --- IMPORT SERVICE THÔNG BÁO ---
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

// Theme
import 'theme/app_theme.dart';

// Screens
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/reset_confirmation_screen.dart';

import 'screens/app_shell.dart';

import 'home/dashboard_screen.dart';
import 'screens/meeting/meeting_screen.dart';
import 'screens/notebook/notebook_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/schedule/schedule_tasks_screen.dart';

import 'screens/meeting/in_meeting_screen.dart';
import 'screens/meeting/post_meeting_summary_screen.dart';
import 'screens/meeting/meeting_setup_screen.dart';
import 'screens/notebook/notebook_detail_screen.dart';

import 'screens/notebook/create_notebook_screen.dart';
import 'screens/schedule/new_task_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/team/team_screen.dart';
import 'screens/team/team_detail_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. KHỞI TẠO TIMEZONE (Cực kỳ quan trọng để thông báo đúng giờ)
  tz.initializeTimeZones();

  // 2. KHỞI TẠO THÔNG BÁO
  await NotificationService().initialize();

  final authProvider = AuthProvider();
  await authProvider.init();

  // Load .env file
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // SỬA: Sử dụng .value và đưa vào danh sách providers, không lồng child ở đây
        ChangeNotifierProvider.value(value: authProvider),
      ],
      // SỬA: child chính của MultiProvider là MyApp
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
            state.uri.path.startsWith('/register') ||
            state.uri.path == '/onboarding' ||
            state.uri.path == '/splash' ||
            state.uri.path == '/reset_password' ||
            state.uri.path == '/reset_confirmation';

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
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
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
              path: '/app/meeting',
              builder: (_, __) => const MeetingScreen(),
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
            GoRoute(
              path: '/app/search',
              builder: (_, __) => const SearchScreen(),
            ),
            GoRoute(
              path: '/app/teams',
              builder: (_, __) => const TeamScreen(),
            ),
            GoRoute(
              path: '/app/team/:teamId',
              builder: (context, state) {
                final teamId = state.pathParameters['teamId']!;
                return TeamDetailScreen(teamId: teamId);
              },
            ),
            // Route tạo Notebook (đã có sẵn)
            GoRoute(
              path: '/create_notebook',
              builder: (context, state) => const CreateNotebookScreen(),
            ),
            // <--- ROUTE TẠO TASK MỚI ---
            GoRoute(
              path: '/app/new_task',
              builder: (context, state) {
                final extra = state.extra;
                String? title;
                String? location;
                DateTime? startTime;
                DateTime? endTime;
                if (extra is Map<String, dynamic>) {
                  title = extra['title'] as String?;
                  location = extra['location'] as String?;
                  startTime = extra['startTime'] as DateTime?;
                  endTime = extra['endTime'] as DateTime?;
                }
                return NewTaskScreen(
                  initialTitle: title,
                  initialLocation: location,
                  initialStartTime: startTime,
                  initialEndTime: endTime,
                );
              },
            ),
            // ---------------------------------
          ],
        ),

        /// OTHER ROUTES OUTSIDE SHELL
        GoRoute(
          path: '/meeting_setup',
          builder: (_, __) => const MeetingSetupScreen(),
        ),

        GoRoute(
          path: '/in_meeting',
          builder: (context, state) {
            final extra = state.extra;
            String? title;
            String? filePath;
            bool aiAgentEnabled = false;
            String? openAiKey;
            if (extra is Map<String, dynamic>) {
              title = extra['title'] as String?;
              filePath = extra['filePath'] as String?;
              aiAgentEnabled = (extra['aiAgentEnabled'] as bool?) ?? false;
              openAiKey = extra['openAiKey'] as String?;
            }
            return InMeetingScreen(
              title: title,
              contextFilePath: filePath,
              aiAgentEnabled: aiAgentEnabled,
              openAiKey: openAiKey,
            );
          },
        ),

        GoRoute(
          path: '/post_summary/:sid',
          builder: (context, state) {
            final sid = state.pathParameters['sid']!;
            return PostMeetingSummaryScreen(
              meetingSid: sid,
            );
          },
        ),
        GoRoute(
          path: '/notebook_detail/:folderId',
          builder: (context, state) {
            final folderId = state.pathParameters['folderId']!;
            return NotebookDetailScreen(folderId: folderId);
          },
        ),
      ],
    );

    NotificationService().setOnNotificationTap((payload) async {
      if (payload == null) return;
      if (payload.startsWith('team_invite:')) {
        final teamId = payload.split(':').last;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_team_invite', teamId);
        router.go('/app/teams');
      } else if (payload.startsWith('team_event:')) {
        final teamId = payload.split(':').last;
        router.go('/app/team/$teamId');
      }
    });

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
