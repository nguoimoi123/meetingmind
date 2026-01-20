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
  // Thay đổi thành instance để có thể truyền userId
  MeetingService? _meetingService;

  List<Meeting> _meetings = [];
  bool _isLoading = true;
  String _searchQuery = "";
  late String _userId;

  @override
  void initState() {
    super.initState();

    // Lấy userId từ AuthProvider (như các màn hình khác)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        setState(() {
          _userId = authProvider.userId!;
          // Khởi tạo Service với userId động
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
      // Gọi fetch từ Service đã có userId
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
        title: const Text('Xóa cuộc họp?'),
        content: Text('Bạn có chắc muốn xóa "${meeting.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _meetingService!.deleteMeeting(meeting.id);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Đã xóa cuộc họp")));
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
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
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
                    prefixIcon: Icon(Icons.search,
                        color: colorScheme.onSurface.withOpacity(0.4)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (filteredMeetings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off_outlined,
                        size: 64, color: colorScheme.outline),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meeting = filteredMeetings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Dismissible(
                        key: Key(meeting.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _confirmDelete(meeting),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.red),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/in_meeting'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Meeting', style: TextStyle(color: Colors.white)),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildDetailedMeetingCard(Meeting meeting, ThemeData theme,
      ColorScheme colorScheme, DateFormat dateFormat) {
    final isCompleted = meeting.status == 'Completed';
    final statusColor =
        isCompleted ? colorScheme.primary : colorScheme.secondary;
    final statusIcon =
        isCompleted ? Icons.check_circle : Icons.play_circle_outline;

    return InkWell(
      onTap: () => context.push('/post_summary/${meeting.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: colorScheme.outline),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(meeting.date),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                Text(
                  "60 mins",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "Participants",
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ...List.generate(
                    meeting.participants.length > 4
                        ? 4
                        : meeting.participants.length, (index) {
                  return Transform.translate(
                    offset: Offset(-12.0 * index, 0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?u=${meeting.participants[index]}"),
                      child: meeting.participants[index].length == 1
                          ? Text(meeting.participants[index][0].toUpperCase(),
                              style: const TextStyle(fontSize: 12))
                          : null,
                    ),
                  );
                }),
                if (meeting.participants.length > 4)
                  Transform.translate(
                    offset: const Offset(-48, 0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.surfaceVariant,
                      child: Text(
                        "+${meeting.participants.length - 4}",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant),
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
