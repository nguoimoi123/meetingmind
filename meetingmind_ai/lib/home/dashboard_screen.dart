import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/services/meeting_service.dart'; // Import service
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/siri.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _userId;

  // Dữ liệu cho 3 phần
  List<Meeting> _recentMeetings = [];
  List<dynamic> _notebooks = [];

  bool _isLoading = true;

  // =================================================================
  // PALETTE MÀU SẮC SỐNG ĐỘNG (Vibrant Palette)
  // Được thiết kế để gán màu cho từng Notebook, tạo cảm giác đa dạng
  // =================================================================
  static const List<Color> _notebookColors = [
    Color(0xFF4285F4), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFFBBC05), // Google Yellow
    Color(0xFFEA4335), // Google Red
    Color(0xFFAA00FF), // Deep Purple
    Color(0xFF00BCD4), // Cyan
  ];
  final List<Color> _btnGradientColors = const [
    Color(0xFF6200EA), // Deep Purple
    Color(0xFF2962FF), // Blue
    Color(0xFF00BFA5), // Teal
    Color(0xFF6200EA), // Lặp lại màu đầu để mượt mà
  ];

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
        // Lọc ra các cuộc họp đã qua (từ giờ hiện tại trở về trước)
        var pastMeetings =
            meetings.where((m) => m.date.isBefore(DateTime.now())).toList();
        pastMeetings
            .sort((a, b) => b.date.compareTo(a.date)); // Sắp xếp mới nhất trước
        _recentMeetings = pastMeetings.take(3).toList();

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
      backgroundColor: colorScheme.surface, // Nền trắng/tối tùy theme
      body: CustomScrollView(
        slivers: [
          // --- HEADER ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
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
                          letterSpacing: -0.5,
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
                  // Avatar với viền rực rỡ
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2962FF), // Màu nổi bật
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage:
                          const NetworkImage('https://i.pravatar.cc/150'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- UPCOMING MEETINGS (Horizontal List) ---
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Text(
                    'Recent Meetings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(
                  height: 180, // Tăng chiều cao cho thẻ đẹp hơn
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _recentMeetings.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text("No recent meetings found"))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _recentMeetings.length,
                              itemBuilder: (context, index) {
                                final meeting = _recentMeetings[index];
                                return _buildMeetingCard(
                                    meeting, colorScheme, theme, dateFormat);
                              },
                            ),
                ),
              ],
            ),
          ),

          // --- TODAY'S SCHEDULE WIDGET (Highlight) ---
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Gradient nhẹ tạo chiều sâu
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2962FF).withOpacity(0.05),
                    const Color(0xFF2962FF).withOpacity(0.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF2962FF).withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2962FF), // Màu nổi bật
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2962FF).withOpacity(0.3),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Schedule",
                          style: theme.textTheme.titleLarge?.copyWith(
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
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => context.push('/app/calendar'),
                      icon: Icon(Icons.arrow_forward,
                          color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- MY NOTEBOOKS (Grid) ---
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Notebooks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "View All",
                          style: TextStyle(
                            color: const Color(0xFF2962FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
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
                      childAspectRatio: 1.1, // Tỷ lệ khung hình vuông hơi dọc
                    ),
                    itemCount: _notebooks.length > 4 ? 4 : _notebooks.length,
                    itemBuilder: (context, index) {
                      final folder = _notebooks[index];
                      return _buildNotebookCard(
                          folder, colorScheme, theme, index);
                    },
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () {},
          elevation: 4,
          backgroundColor: const Color(0xFF2962FF),
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

  Widget _buildMeetingCard(Meeting meeting, ColorScheme colorScheme,
      ThemeData theme, DateFormat dateFormat) {
    return Container(
      width: 220, // Tăng chiều rộng một chút
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24), // Bo tròn nhiều hơn
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
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
            children: [
              // Icon Video nổi bật
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam,
                    color: Color(0xFF2962FF), size: 18),
              ),
              // Chip thời gian
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meeting.time,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            meeting.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const Spacer(),
          // Ngày tháng
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(meeting.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Avatar người tham gia (Style giống NotebookLM Sources)
          Row(
            children: List.generate(
                meeting.participants.length > 3
                    ? 3
                    : meeting.participants.length, (index) {
              return Transform.translate(
                offset: Offset(-12.0 * index, 0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=${meeting.participants[index]}'), // Giả định avatar
                  child: meeting.participants[index].isEmpty ? null : null,
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildNotebookCard(
      dynamic folder, ColorScheme colorScheme, ThemeData theme, int index) {
    // Lấy màu từ palette theo index
    final folderColor = _notebookColors[index % _notebookColors.length];

    return InkWell(
      onTap: () => context.push('/notebook_detail/${folder['id']}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Folder với màu sắc đa dạng theo index
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: folderColor.withOpacity(0.1), // Màu nền nhạt của icon
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  Icon(Icons.description_rounded, size: 28, color: folderColor),
            ),
            const SizedBox(height: 16),
            Text(
              folder['name'] ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              folder['description'] ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
