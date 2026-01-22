import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/widgets/dashboard.dart';
import 'package:meetingmind_ai/home/siri_screen.dart';
import 'package:go_router/go_router.dart';

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
        var pastMeetings =
            meetings.where((m) => m.date.isBefore(DateTime.now())).toList();
        pastMeetings.sort((a, b) => b.date.compareTo(a.date));
        _recentMeetings = pastMeetings.take(3).toList();
        _notebooks = notebooks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM');
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 18 ? 'Good Afternoon' : 'Good Evening');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
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
                    height: 180,
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
                                  return MeetingCard(
                                    meeting: meeting,
                                    dateFormat: dateFormat,
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),

            // --- TODAY'S SCHEDULE ---
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
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
                        color: const Color(0xFF2962FF),
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

            // --- MY NOTEBOOKS ---
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
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _notebooks.length > 4 ? 4 : _notebooks.length,
                      itemBuilder: (context, index) {
                        final folder = _notebooks[index];
                        return NotebookCard(
                          folder: folder,
                          index: index,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100), // Khoảng trống cho nút FAB
                ],
              ),
            ),
          ],
        ),
      ),
      // --- ANIMATED GRADIENT CIRCLE ---
      floatingActionButton: AnimatedGradientFAB(
        animationController: _animationController,
        rotationAnimation: _rotationAnimation,
        pulseAnimation: _pulseAnimation,
        bottomPadding: bottomPadding,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VoiceSelectionScreen(),
            ),
          );
        },
      ),
    );
  }
}
