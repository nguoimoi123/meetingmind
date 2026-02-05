import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:meetingmind_ai/services/meeting_management_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

// import '../widgets/siri.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late String _userId;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  // Dữ liệu cho 3 phần
  List<Meeting> _recentMeetings = [];
  List<dynamic> _notebooks = [];

  bool _isLoading = true;
  bool _agendaLoading = false;

  // =================================================================
  // PALETTE MÀU SẮC SỐNG ĐỘNG (Vibrant Palette)
  // =================================================================
  static const List<Color> _notebookColors = [
    Color(0xFF4285F4), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFFBBC05), // Google Yellow
    Color(0xFFEA4335), // Google Red
    Color(0xFFAA00FF), // Deep Purple
    Color(0xFF00BCD4), // Cyan
  ];

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159, // 2π radians (360 degrees)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId!;
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final meetingService = MeetingService(_userId);
      final meetings = await meetingService.getPastMeetings();
      final notebooks = await NotebookListService.fetchFolders(_userId);

      setState(() {
        // Lọc ra các cuộc họp sắp tới (từ giờ hiện tại trở đi)
        // Lọc ra các cuộc họp đã qua (từ giờ hiện tại trở về trước)
        var pastMeetings =
            meetings.where((m) => m.date.isBefore(DateTime.now())).toList();
        pastMeetings
            .sort((a, b) => b.date.compareTo(a.date)); // Sắp xếp mới nhất trước
        _recentMeetings = pastMeetings.take(4).toList();

        _notebooks = notebooks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAgendaSuggestions() async {
    if (_agendaLoading) return;
    setState(() => _agendaLoading = true);

    try {
      final data = await MeetingManagementService.getNextAgenda(
        userId: _userId,
        limit: 5,
      );

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final agendaItems = (data['agenda_items'] as List?) ?? [];
          final goals = (data['goals'] as List?) ?? [];
          final risks = (data['risks'] as List?) ?? [];
          final followUps = (data['follow_ups'] as List?) ?? [];

          Widget buildList(String title, List items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...items.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.toString())),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Agenda Suggestions',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    buildList('Agenda Items', agendaItems),
                    buildList('Goals', goals),
                    buildList('Risks', risks),
                    buildList('Follow-ups', followUps),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy agenda: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _agendaLoading = false);
    }
  }
  // -------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM');
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.googleUser;
    final rawName = user?.displayName?.trim();
    final localName = authProvider.name?.trim();
    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(RegExp(r'\s+')).first
        : (localName != null && localName.isNotEmpty
            ? localName.split(RegExp(r'\s+')).first
            : (authProvider.isLoggedIn ? 'User' : 'Guest'));
    final avatarUrl = user?.photoUrl;

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
                        '$greeting, $displayName',
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
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Icon(Icons.person, color: colorScheme.onSurface)
                          : null,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Meetings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/app/meeting'),
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
                          'Let\'s review your schedule',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2962FF),
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

          // --- RECENT MEETINGS ---
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recentMeetings.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text("No recent meetings found"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _recentMeetings.length,
                          itemBuilder: (context, index) {
                            final meeting = _recentMeetings[index];
                            return _buildMeetingCard(
                                meeting, colorScheme, theme, dateFormat);
                          },
                        ),
            ),
          ),

          // --- AI AGENDA SUGGESTIONS ---
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF2962FF).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2962FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF2962FF), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Agenda Suggestions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get ideas for your next meeting agenda',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _agendaLoading ? null : _showAgendaSuggestions,
                    icon: _agendaLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
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
                // ĐÃ CHỈNH SỬA: Giảm padding top từ 16 xuống 8
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Notebooks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () => context.push('/app/notebooks'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
      //   child: FloatingActionButton.extended(
      //     onPressed: () {},
      //     elevation: 4,
      //     backgroundColor: const Color(0xFF2962FF),
      //     icon: const Icon(Icons.add, color: Colors.white),
      //     label: const Text('New',
      //         style:
      //             TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      //     shape:
      //         RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      //   ),
      // ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting, ColorScheme colorScheme,
      ThemeData theme, DateFormat dateFormat) {
    return InkWell(
      onTap: () => context.push('/post_summary/${meeting.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
