import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int? _selectedIndexFor(String location) {
    if (location.startsWith('/app/home')) {
      return 0;
    }
    if (location.startsWith('/app/meeting') ||
        location.startsWith('/meeting_setup')) {
      return 1;
    }
    if (location.startsWith('/app/notebooks') ||
        location.startsWith('/create_notebook') ||
        location.startsWith('/notebook_detail')) {
      return 2;
    }
    if (location.startsWith('/app/calendar') ||
        location.startsWith('/app/new_task')) {
      return 3;
    }
    if (location.startsWith('/app/profile')) {
      return 4;
    }
    return null;
  }

  bool _shouldShowBottomNav(String location) {
    return location.startsWith('/app/home') ||
        location.startsWith('/app/meeting') ||
        location.startsWith('/meeting_setup') ||
        location.startsWith('/app/notebooks') ||
        location.startsWith('/create_notebook') ||
        location.startsWith('/app/calendar') ||
        location.startsWith('/app/new_task') ||
        location.startsWith('/app/profile');
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri.path;
    final selectedIndex = _selectedIndexFor(location);
    final showBottomNav = _shouldShowBottomNav(location);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final tabs = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.tr('navHome'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.videocam_outlined),
        selectedIcon: const Icon(Icons.videocam),
        label: l10n.tr('navMeeting'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.book_outlined),
        selectedIcon: const Icon(Icons.book),
        label: l10n.tr('navNotebooks'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_today_outlined),
        selectedIcon: const Icon(Icons.calendar_month),
        label: l10n.tr('navCalendar'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: l10n.tr('navProfile'),
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
              selectedIndex: selectedIndex ?? 0,
              height: 74,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    router.go('/app/home');
                    break;
                  case 1:
                    router.go('/app/meeting');
                    break;
                  case 2:
                    router.go('/app/notebooks');
                    break;
                  case 3:
                    router.go('/app/calendar');
                    break;
                  case 4:
                    router.go('/app/profile');
                    break;
                }
              },
              destinations: tabs,
              backgroundColor: theme.colorScheme.surface,
              shadowColor: Colors.transparent,
            )
          : null,
    );
  }
}
