import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:meetingmind_ai/models/event_model.dart';
import 'package:meetingmind_ai/services/reminder_service.dart';
import 'package:meetingmind_ai/services/notification_service.dart';
import 'new_task_screen.dart';
import '../../providers/auth_provider.dart';

class ScheduleTasksScreen extends StatefulWidget {
  const ScheduleTasksScreen({super.key});

  @override
  State<ScheduleTasksScreen> createState() => _ScheduleTasksScreenState();
}

class _ScheduleTasksScreenState extends State<ScheduleTasksScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedDay;

  Future<List<Event>>? _eventsFuture;
  late String _userId;

  // Màu sắc chủ đạo theo phong cách NotebookLM
  static const Color _vibrantBlue = Color(0xFF2962FF);
  static const Color _textPrimary = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedDate = now;
    _focusedDay = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId!;
      _refreshData();
    });
  }

  void _refreshData() {
    setState(() {
      _eventsFuture = ReminderService.fetchEvents(
        userId: _userId,
        date: _selectedDate,
      );
    });
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _focusedDay = newDate;
    });
    _refreshData();
  }

  List<DateTime> _getWeekDays(DateTime focusDate) {
    int currentWeekday = focusDate.weekday;
    DateTime monday = focusDate.subtract(Duration(days: currentWeekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  void _changeWeek(int weeksOffset) {
    final newFocusedDay = _focusedDay.add(Duration(days: 7 * weeksOffset));
    setState(() {
      _focusedDay = newFocusedDay;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _vibrantBlue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      _updateSelectedDate(picked);
    }
  }

  Future<void> _openAddTaskScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTaskScreen()),
    );

    if (result == true && mounted) {
      _refreshData();
    }
  }

  Future<void> _deleteEvent(
      String eventId, String eventTitle, String startTime) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "$eventTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ReminderService.deleteReminder(
          userId: _userId,
          reminderId: eventId,
        );

        try {
          final parts = startTime.split(':');
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);

            final notificationDate = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              hour,
              minute,
            );

            final notificationId =
                notificationDate.millisecondsSinceEpoch ~/ 1000;

            await NotificationService().cancelNotification(notificationId);
          }
        } catch (e) {
          print("Error cancelling local notification: $e");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted')),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<DateTime> weekDays = _getWeekDays(_focusedDay);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER & MONTH NAVIGATOR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Schedule",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today_rounded),
                        onPressed: _pickDate,
                        color: _vibrantBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMonthNavigator(theme, colorScheme),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- WEEK SELECTOR (Modern Pills) ---
            _buildWeekSelector(weekDays, theme, colorScheme),

            const SizedBox(height: 24),

            // --- TIMELINE HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateHeader(_selectedDate),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _vibrantBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getDayName(_selectedDate.weekday)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _vibrantBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- EVENT LIST ---
            Expanded(
              child: _eventsFuture == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<List<Event>>(
                      future: _eventsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return _buildErrorState(
                              theme, colorScheme, snapshot.error.toString());
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return _buildEmptyState(theme, colorScheme);
                        } else {
                          final events = snapshot.data!;
                          return _buildTimeline(events, theme, colorScheme);
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
      // --- FLOATING ACTION BUTTON (Vibrant) ---
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: _openAddTaskScreen,
          elevation: 4,
          backgroundColor: _vibrantBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'New Task',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavigator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
              () => _changeWeek(-1), Icons.chevron_left, colorScheme),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _formatMonthYear(_focusedDay),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          _buildNavButton(
              () => _changeWeek(1), Icons.chevron_right, colorScheme),
        ],
      ),
    );
  }

  Widget _buildNavButton(
      VoidCallback onPressed, IconData icon, ColorScheme colorScheme) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildWeekSelector(
      List<DateTime> days, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, _selectedDate);
          final isToday = _isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () => _updateSelectedDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? _vibrantBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _vibrantBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(day.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _vibrantBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(
      List<Event> events, ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(events.length, (index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TIME LABEL ---
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.startTime,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        event.endTime,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- TIMELINE LINE ---
                Container(
                  width: 2,
                  height: 100, // Chiều cao cố định cho thanh line
                  margin: const EdgeInsets.only(left: 8, right: 20),
                  decoration: BoxDecoration(
                    color: event.colorTag.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(
                            top: 14), // Canh giữa với text giờ
                        decoration: BoxDecoration(
                          color: event.colorTag,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: event.colorTag.withOpacity(0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- EVENT CARD ---
                Expanded(
                  child: _buildEventCard(event, theme, colorScheme),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEventCard(
      Event event, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- COLOR TAG ICON (NotebookLM Style) ---
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: event.colorTag.withOpacity(0.1), // Nền nhạt cùng màu tag
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.circle_rounded, // Icon tròn đơn giản nhưng hiệu quả
              size: 16,
              color: event.colorTag,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // --- DELETE BUTTON ---
          IconButton(
            onPressed: () =>
                _deleteEvent(event.id, event.title, event.startTime),
            icon: Icon(Icons.delete_outline_rounded,
                color: colorScheme.error.withOpacity(0.7)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded,
                size: 48, color: colorScheme.onSurface.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            'No events scheduled',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      ThemeData theme, ColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded,
                size: 48, color: colorScheme.error),
          ),
          const SizedBox(height: 24),
          Text(
            'Connection Error',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Could not load events. Please check your server.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vibrantBlue,
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  // Helpers
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return 'Tomorrow';
    return '${date.day} ${_getMonthName(date.month)}';
  }

  String _formatMonthYear(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
