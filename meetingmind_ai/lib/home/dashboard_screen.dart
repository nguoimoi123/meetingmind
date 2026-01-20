import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/services/meeting_service.dart'; // Import service
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _userId;

  // Dữ liệu cho 3 phần
  List<Meeting> _upcomingMeetings = [];
  List<dynamic> _notebooks = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId!;
      _loadData();
    });
  }

  // --- SỬA HÀM FETCH ĐÂY ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Tạo Service và truyền userId (QUAN TRỌNG)
      final meetingService = MeetingService(_userId);

      // 2. Lấy danh sách Meeting
      final meetings = await meetingService.getPastMeetings();

      // 3. Lấy danh sách Notebook (Giữ nguyên cũ)
      final notebooks = await NotebookListService.fetchFolders(_userId);

      setState(() {
        // Lọc ra các cuộc họp sắp tới (từ giờ hiện tại trở đi)
        _upcomingMeetings = meetings
            .where((m) => m.date.isAfter(DateTime.now()))
            .take(3) // Chỉ lấy 3 cái đầu để preview
            .toList();

        _notebooks = notebooks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      setState(() => _isLoading = false);
    }
  }
  // -------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM');

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 18 ? 'Good Afternoon' : 'Good Evening');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, User',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Let\'s review your schedule',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage:
                        const NetworkImage('https://i.pravatar.cc/150'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'Upcoming Meetings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _upcomingMeetings.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text("No upcoming meetings found"))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _upcomingMeetings.length,
                              itemBuilder: (context, index) {
                                final meeting = _upcomingMeetings[index];
                                return _buildMeetingCard(
                                    meeting, colorScheme, theme, dateFormat);
                              },
                            ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.calendar_today,
                        color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Schedule",
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You have events coming up. Check details.",
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/app/calendar'),
                    icon: Icon(Icons.arrow_forward, color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'My Notebooks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _notebooks.length > 4 ? 4 : _notebooks.length,
                    itemBuilder: (context, index) {
                      final folder = _notebooks[index];
                      return _buildNotebookCard(folder, colorScheme, theme);
                    },
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting, ColorScheme colorScheme,
      ThemeData theme, DateFormat dateFormat) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.videocam,
                    color: colorScheme.onTertiary, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meeting.time,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meeting.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(meeting.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
                meeting.participants.length > 3
                    ? 3
                    : meeting.participants.length, (index) {
              return Transform.translate(
                offset: Offset(-8.0 * index, 0),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    meeting.participants[index][0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 10, color: colorScheme.onPrimaryContainer),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildNotebookCard(
      dynamic folder, ColorScheme colorScheme, ThemeData theme) {
    return InkWell(
      onTap: () => context.push('/notebook_detail/${folder['id']}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_rounded, size: 32, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              folder['name'] ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              folder['description'] ?? 'No description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
