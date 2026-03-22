import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_confirmation_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/meeting/presentation/screens/in_meeting_screen.dart';
import 'features/meeting/presentation/screens/meeting_screen.dart';
import 'features/meeting/presentation/screens/meeting_setup_screen.dart';
import 'features/meeting/presentation/screens/post_meeting_summary_screen.dart';
import 'features/notebook/presentation/screens/create_notebook_screen.dart';
import 'features/notebook/presentation/screens/notebook_detail_screen.dart';
import 'features/notebook/presentation/screens/notebook_list_screen.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_shell.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/schedule/new_task_screen.dart';
import 'screens/schedule/schedule_tasks_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/team/team_detail_screen.dart';
import 'screens/team/team_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initialize();

  final authProvider = AuthProvider();
  await authProvider.init();

  await dotenv.load(fileName: '.env');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      debugLogDiagnostics: true,
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final goingToAuth = state.uri.path.startsWith('/login') ||
            state.uri.path.startsWith('/register') ||
            state.uri.path == '/onboarding' ||
            state.uri.path == '/splash' ||
            state.uri.path == '/reset_password' ||
            state.uri.path == '/reset_confirmation';

        if (!loggedIn && !goingToAuth) {
          return '/splash';
        }

        if (loggedIn && goingToAuth) {
          return '/app/home';
        }

        return null;
      },
      routes: [
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
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
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
              path: '/app/meeting/setup',
              builder: (_, __) => const MeetingSetupScreen(),
            ),
            GoRoute(
              path: '/app/notebooks',
              builder: (_, __) => const NotebookListScreen(),
            ),
            GoRoute(
              path: '/app/notebooks/create',
              builder: (context, state) => const CreateNotebookScreen(),
            ),
            GoRoute(
              path: '/app/calendar',
              builder: (_, __) => const ScheduleTasksScreen(),
            ),
            GoRoute(
              path: '/app/calendar/new',
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
            GoRoute(
              path: '/app/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/app/notifications',
              builder: (_, __) => const NotificationsScreen(),
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
          ],
        ),
        GoRoute(
          path: '/meeting_setup',
          redirect: (_, __) => '/app/meeting/setup',
        ),
        GoRoute(
          path: '/in_meeting',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra;
            String? title;
            String? filePath;
            var aiAgentEnabled = false;
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
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final sid = state.pathParameters['sid']!;
            return PostMeetingSummaryScreen(meetingSid: sid);
          },
        ),
        GoRoute(
          path: '/notebook_detail/:folderId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final folderId = state.pathParameters['folderId']!;
            return NotebookDetailScreen(folderId: folderId);
          },
        ),
      ],
    );

    NotificationService().setOnNotificationTap((payload) async {
      if (payload == null) {
        return;
      }
      if (payload.startsWith('team_invite:')) {
        final teamId = payload.split(':').last;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_team_invite', teamId);
        router.go('/app/teams');
      } else if (payload.startsWith('team_event:')) {
        final teamId = payload.split(':').last;
        router.go('/app/team/$teamId');
      } else if (payload.startsWith('upgrade_code:')) {
        router.go('/app/profile');
      } else if (payload == 'app_notifications' ||
          payload == 'plan_upgrade_code' ||
          payload == 'system') {
        router.go('/app/notifications');
      }
    });

    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (_, themeProvider, localeProvider, __) {
        return MaterialApp.router(
          title: 'MeetingMind AI',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          darkTheme: AppTheme.dark,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        );
      },
    );
  }
}
