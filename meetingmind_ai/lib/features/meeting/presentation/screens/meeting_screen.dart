import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';
import 'package:meetingmind_ai/features/meeting/logic/meeting_list_logic.dart';
import 'package:meetingmind_ai/features/meeting/presentation/widgets/meeting_delete_dialog.dart';
import 'package:meetingmind_ai/features/meeting/presentation/widgets/meeting_empty_state.dart';
import 'package:meetingmind_ai/features/meeting/presentation/widgets/meeting_list_item.dart';
import 'package:meetingmind_ai/features/meeting/presentation/widgets/meeting_search_bar.dart';
import 'package:meetingmind_ai/features/meeting/presentation/widgets/meeting_tag_dialog.dart';
import 'package:meetingmind_ai/features/meeting/presentation/widgets/meeting_tag_filters.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/meeting_management_service.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:provider/provider.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  MeetingService? _meetingService;
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedTag;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) {
        return;
      }

      setState(() {
        _meetingService = MeetingService(userId);
      });
      _loadMeetings();
    });
  }

  Future<void> _loadMeetings() async {
    if (_meetingService == null) return;

    setState(() => _isLoading = true);
    try {
      final meetings = await _meetingService!.getPastMeetings();
      if (mounted) {
        setState(() => _meetings = meetings);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr('failedLoadMeetings', params: {'error': '$e'}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editTags(Meeting meeting) async {
    final result = await showMeetingTagDialog(
      context,
      initialTags: meeting.tags,
    );

    if (result == null) return;

    try {
      final updated = await MeetingManagementService.updateMeetingTags(
        sid: meeting.id,
        tags: result,
      );

      if (!mounted) return;

      setState(() {
        final index = _meetings.indexWhere((item) => item.id == meeting.id);
        if (index != -1) {
          _meetings[index] = MeetingListLogic.copyWithTags(meeting, updated);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('tagsUpdated'))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr('failedUpdateTags', params: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    if (_meetingService == null) return;
    try {
      await _meetingService!.deleteMeeting(meeting.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('meetingDeleted'))),
      );
      await _loadMeetings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr('failedDeleteMeeting', params: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final l10n = context.l10n;
    final tags = MeetingListLogic.collectTags(_meetings);
    final filteredMeetings = MeetingListLogic.filterMeetings(
      meetings: _meetings,
      searchQuery: _searchQuery,
      selectedTag: _selectedTag,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          MeetingSearchBar(
            value: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: () => setState(() => _searchQuery = ''),
            onSearchTap: () => context.push('/app/search'),
          ),
          MeetingTagFilters(
            tags: tags,
            selectedTag: _selectedTag,
            onSelected: (tag) => setState(() => _selectedTag = tag),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredMeetings.isEmpty)
            const SliverFillRemaining(child: MeetingEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meeting = filteredMeetings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Dismissible(
                        key: Key(meeting.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => showMeetingDeleteDialog(
                          context,
                          title: meeting.title,
                        ),
                        onDismissed: (_) => _deleteMeeting(meeting),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        child: MeetingListItem(
                          meeting: meeting,
                          dateFormat: dateFormat,
                          onEditTags: () => _editTags(meeting),
                        ),
                      ),
                    );
                  },
                  childCount: filteredMeetings.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/app/meeting/setup'),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            l10n.tr('newLabel'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }
}
