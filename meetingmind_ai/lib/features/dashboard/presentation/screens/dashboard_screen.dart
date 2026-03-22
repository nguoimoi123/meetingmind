import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:meetingmind_ai/features/dashboard/logic/dashboard_logic.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_agenda_card.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_agenda_sheet.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_meeting_card.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_notebook_card.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_notifications_banner.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_schedule_card.dart';
import 'package:meetingmind_ai/features/dashboard/presentation/widgets/dashboard_section_title.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/providers/notification_provider.dart';
import 'package:meetingmind_ai/services/meeting_management_service.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<Color> _notebookColors = [
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFFBBC05),
    Color(0xFFEA4335),
    Color(0xFFAA00FF),
    Color(0xFF00BCD4),
  ];

  List<Meeting> _recentMeetings = [];
  List<dynamic> _notebooks = [];
  bool _isLoading = true;
  bool _agendaLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId;
      if (_userId != null) {
        context.read<NotificationProvider>().bindUser(_userId);
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await DashboardLogic.load(_userId!);
      if (mounted) {
        setState(() {
          _recentMeetings = data.recentMeetings;
          _notebooks = data.notebooks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr('dashboardError', params: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showAgendaSuggestions() async {
    if (_agendaLoading || _userId == null) return;

    setState(() => _agendaLoading = true);
    try {
      final data = await MeetingManagementService.getNextAgenda(
        userId: _userId!,
        limit: 5,
      );
      if (!mounted) return;
      await showDashboardAgendaSheet(context, data: data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy agenda: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _agendaLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd MMM');
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final l10n = context.l10n;
    final header = DashboardLogic.buildHeader(
      googleDisplayName: authProvider.googleUser?.displayName,
      localName: authProvider.name,
      isLoggedIn: authProvider.isLoggedIn,
      avatarUrl: authProvider.googleUser?.photoUrl,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHeader(
              greeting: header.greeting,
              displayName: header.displayName,
              avatarUrl: header.avatarUrl,
            ),
          ),
          if (notificationProvider.items.isNotEmpty)
            SliverToBoxAdapter(
              child: DashboardNotificationsBanner(
                items: notificationProvider.items,
                unreadCount: notificationProvider.unreadCount,
                onTap: () => context.push('/app/notifications'),
              ),
            ),
          SliverToBoxAdapter(
            child: DashboardSectionTitle(
              title: l10n.tr('recentMeetings'),
              actionLabel: l10n.tr('viewAll'),
              onTap: () => context.push('/app/meeting'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recentMeetings.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(l10n.tr('noRecentMeetings')),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _recentMeetings.length,
                          itemBuilder: (context, index) {
                            final meeting = _recentMeetings[index];
                            return DashboardMeetingCard(
                              meeting: meeting,
                              dateFormat: dateFormat,
                            );
                          },
                        ),
            ),
          ),
          const SliverToBoxAdapter(child: DashboardScheduleCard()),
          SliverToBoxAdapter(
            child: DashboardAgendaCard(
              isLoading: _agendaLoading,
              onTap: _showAgendaSuggestions,
            ),
          ),
          SliverToBoxAdapter(
            child: DashboardSectionTitle(
              title: l10n.tr('myNotebooks'),
              actionLabel: l10n.tr('viewAll'),
              onTap: () => context.push('/app/notebooks'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _notebooks.length > 4 ? 4 : _notebooks.length,
                itemBuilder: (context, index) {
                  final folder = _notebooks[index];
                  return DashboardNotebookCard(
                    folder: folder,
                    folderColor:
                        _notebookColors[index % _notebookColors.length],
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
