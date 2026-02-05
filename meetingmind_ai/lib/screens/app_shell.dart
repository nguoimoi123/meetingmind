import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/dashboard_screen.dart';
import 'notebook/notebook_list_screen.dart';
import 'schedule/schedule_tasks_screen.dart';
import 'profile/profile_screen.dart';

class AppShell extends StatelessWidget {
  final Widget child; // <-- BẮT BUỘC CÓ

  const AppShell({super.key, required this.child});

  static const List<NavigationDestination> _tabs = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.videocam_outlined),
      selectedIcon: Icon(Icons.videocam),
      label: 'Meeting',
    ),
    NavigationDestination(
      icon: Icon(Icons.book_outlined),
      selectedIcon: Icon(Icons.book),
      label: 'Notebooks',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  int _getSelectedIndex(String location) {
    if (location.startsWith('/app/home')) return 0;
    if (location.startsWith('/app/meeting')) return 1;
    if (location.startsWith('/app/notebooks') || location.startsWith('/create_notebook') || location.startsWith('/notebook_detail')) return 2;
    if (location.startsWith('/app/calendar')) return 3;
    if (location.startsWith('/app/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri.path;
    final selectedIndex = _getSelectedIndex(location);
    final theme = Theme.of(context);

    return Scaffold(
      body: child, // <-- DÙNG CHILD Ở ĐÂY
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
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
        destinations: _tabs,
        backgroundColor: theme.scaffoldBackgroundColor,
        indicatorColor: theme.colorScheme.primary,
      ),
    );
  }
}
