import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
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
  String _searchQuery = "";
  late String _userId;

  // Màu sắc rực rỡ dùng cho UI
  static const Color _vibrantBlue = Color(0xFF2962FF);
  static const Color _successGreen = Color(0xFF00C853);
  static const Color _warningOrange = Color(0xFFFF6D00);
  static const Color _dangerRed = Color(0xFFD50000);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        setState(() {
          _userId = authProvider.userId!;
          _meetingService = MeetingService(_userId);
          _loadMeetings();
        });
      }
    });
  }

  Future<void> _loadMeetings() async {
    if (_meetingService == null) return;

    setState(() => _isLoading = true);
    try {
      final meetings = await _meetingService!.getPastMeetings();

      if (mounted) setState(() => _meetings = meetings);
    } catch (e) {
      print("Error loading meetings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(Meeting meeting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa cuộc họp?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa "${meeting.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: _dangerRed,
                backgroundColor: _dangerRed.withOpacity(0.1)),
            child: Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _meetingService!.deleteMeeting(meeting.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Đã xóa cuộc họp"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadMeetings(); // Reload lại
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    final filteredMeetings = _meetings.where((m) {
      return m.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // --- APP BAR & SEARCH ---
          SliverAppBar(
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            centerTitle: false,
            title: Text(
              'My Meetings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search meetings...',
                    hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.4)),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: _vibrantBlue),
                    // Nút xóa text khi có nội dung
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ""),
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: _vibrantBlue, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // --- LIST CONTENT ---
          if (_isLoading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (filteredMeetings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.videocam_off_outlined,
                          size: 48, color: colorScheme.outline),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No meetings found',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 100), // Padding bottom cho FAB
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meeting = filteredMeetings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Dismissible(
                        key: Key(meeting.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _confirmDelete(meeting),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _dangerRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_rounded,
                              color: Colors.white),
                        ),
                        child: _buildDetailedMeetingCard(
                            meeting, theme, colorScheme, dateFormat),
                      ),
                    );
                  },
                  childCount: filteredMeetings.length,
                ),
              ),
            ),
        ],
      ),
      // --- FLOATING ACTION BUTTON ---
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/in_meeting'),
          elevation: 4,
          backgroundColor: _vibrantBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      ),
    );
  }

  Widget _buildDetailedMeetingCard(Meeting meeting, ThemeData theme,
      ColorScheme colorScheme, DateFormat dateFormat) {
    // Logic màu sắc cho trạng thái
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    // Giả lập các trạng thái dựa trên model hoặc logic
    if (meeting.status == 'Completed' ||
        meeting.date.isBefore(DateTime.now())) {
      statusColor = _successGreen;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = "Done";
    } else if (meeting.status == 'Live') {
      statusColor = _dangerRed;
      statusIcon = Icons.fiber_manual_record_rounded;
      statusLabel = "Live";
    } else {
      statusColor = _warningOrange; // Hoặc màu xanh dương nếu muốn
      statusIcon = Icons.upcoming_rounded;
      statusLabel = "Upcoming";
    }

    return InkWell(
      onTap: () => context.push('/post_summary/${meeting.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          // Viền nhẹ tinh tế
          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    meeting.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon trạng thái được tô màu rực rỡ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Thông tin thời gian với Icon màu sống động
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _vibrantBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today_rounded,
                      color: _vibrantBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  dateFormat.format(meeting.date),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  "60 mins",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Phần người tham gia
            Row(
              children: [
                Icon(Icons.group_rounded,
                    color: _vibrantBlue, size: 20), // Icon nhóm màu sống động
                const SizedBox(width: 8),
                Text(
                  "${meeting.participants.length} Participants",
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Stack avatars
                ...List.generate(
                    meeting.participants.length > 4
                        ? 4
                        : meeting.participants.length, (index) {
                  return Transform.translate(
                    offset: Offset(-12.0 * index, 0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surface,
                      // Viền trắng/tối để tách biệt các avatar
                      foregroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?u=${meeting.participants[index]}"),
                      child: meeting.participants[index].length == 1
                          ? Text(meeting.participants[index][0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold))
                          : null,
                    ),
                  );
                }),
                if (meeting.participants.length > 4)
                  Transform.translate(
                    offset: const Offset(-48, 0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: Text(
                        "+${meeting.participants.length - 4}",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
