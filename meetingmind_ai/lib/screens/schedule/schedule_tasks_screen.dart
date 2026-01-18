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

  // Future để chứa dữ liệu từ API
  // Khởi tạo là null, sẽ được gán giá trị sau khi lấy được userId
  Future<List<Event>>? _eventsFuture;

  // Biến lưu userId động
  late String _userId;

  @override
  void initState() {
    super.initState();

    // Đã khởi tạo ở main.dart rồi, nên không cần gọi lại ở đây nữa
    // NotificationService().initialize();

    final now = DateTime.now();
    _selectedDate = now;
    _focusedDay = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId!;
      _refreshData();
    });
  }

  // Hàm tiện ích để gọi lại API và setState
  void _refreshData() {
    setState(() {
      _eventsFuture = ReminderService.fetchEvents(
        userId: _userId,
        date: _selectedDate,
      );
    });
  }

  // Hàm reset dữ liệu khi đổi ngày
  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _focusedDay = newDate;
    });
    // Gọi lại API với userId động và ngày mới
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
                  primary: const Color(0xFF6366F1),
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

    // Nếu result là true, tải lại dữ liệu với userId động
    if (result == true && mounted) {
      _refreshData();
    }
  }

  // --- HÀM XỬ LÝ XÓA (ĐÃ SỬA ĐỂ HỦY THÔNG BÁO ĐÚNG ID) ---
  Future<void> _deleteEvent(
      String eventId, String eventTitle, String startTime) async {
    // Tham số startTime được thêm vào để tính toán ID notification
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
        // 1. Xóa trên API
        await ReminderService.deleteReminder(
          userId: _userId,
          reminderId: eventId,
        );

        // 2. TÍNH TOÁN LẠI ID ĐỂ HỦY THÔNG BÁO CỤC BỘ
        try {
          final parts = startTime.split(':');
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);

            // Tái tạo lại DateTime đúng lúc tạo task (Ngày đang xem + giờ bắt đầu của task)
            final notificationDate = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              hour,
              minute,
            );

            // Tính lại ID giống lúc đặt notification
            final notificationId =
                notificationDate.millisecondsSinceEpoch ~/ 1000;

            // Hủy thông báo
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Schedule",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthNavigator(theme, colorScheme),
          const SizedBox(height: 12),
          _buildWeekSelector(weekDays, theme, colorScheme),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateHeader(_selectedDate),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Schedule',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _eventsFuture == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Event>>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return _buildErrorState(
                            theme, colorScheme, snapshot.error.toString());
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTaskScreen,
        backgroundColor: colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Task',
          style: TextStyle(
              color: colorScheme.onSecondary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMonthNavigator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
            splashRadius: 24,
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _formatMonthYear(_focusedDay),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeWeek(1),
            icon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(
      List<DateTime> days, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 90,
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
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.secondary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.secondary.withValues(alpha: 0.3),
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
                          ? colorScheme.onSecondary.withValues(alpha: 0.8)
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.onSecondary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
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
                SizedBox(
                  width: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        event.startTime,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        event.endTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: event.colorTag.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: event.colorTag,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
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
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: event.colorTag,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // --- SỬA: THÊM event.startTime VÀO HÀM XÓA ---
              GestureDetector(
                onTap: () =>
                    _deleteEvent(event.id, event.title, event.startTime),
                child: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
          if (event.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  event.location!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded,
              size: 64, color: colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No events scheduled',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
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
          Icon(Icons.wifi_off_rounded,
              size: 64, color: colorScheme.error.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: theme.textTheme.titleMedium?.copyWith(
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
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Retry'),
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
    return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
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
