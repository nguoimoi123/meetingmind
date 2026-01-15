import 'package:flutter/material.dart';

// Model dữ liệu sự kiện (Giữ nguyên)
class Event {
  final String title;
  final String startTime;
  final String endTime;
  final String? location;
  final Color colorTag;
  final bool isCompleted;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.colorTag,
    this.isCompleted = false,
  });
}

class ScheduleTasksScreen extends StatefulWidget {
  const ScheduleTasksScreen({super.key});

  @override
  State<ScheduleTasksScreen> createState() => _ScheduleTasksScreenState();
}

class _ScheduleTasksScreenState extends State<ScheduleTasksScreen> {
  // Ngày đang được chọn (để hiển thị sự kiện cụ thể)
  late DateTime _selectedDate;

  // Ngày đang được focus (để xác định tuần nào đang được hiển thị trên thanh chọn)
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _focusedDay = now; // Ban đầu focus vào hôm nay
  }

  // Lấy danh sách 7 ngày của tuần chứa ngày `focusDate` đã cho
  List<DateTime> _getWeekDays(DateTime focusDate) {
    // Tìm ngày Thứ 2 của tuần chứa focusDate
    // Weekday: 1 = Monday, 7 = Sunday
    int currentWeekday = focusDate.weekday;
    DateTime monday = focusDate.subtract(Duration(days: currentWeekday - 1));

    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  // --- LOGIC CHUYỂN TRANG ---
  void _changeFocusedDate(DateTime newDate) {
    setState(() {
      _focusedDay = newDate;
    });
  }

  // Chuyển tuần
  void _changeWeek(int weeksOffset) {
    final newFocusedDay = _focusedDay.add(Duration(days: 7 * weeksOffset));
    _changeFocusedDate(newFocusedDay);
  }

  // Mở DatePicker để chọn tổng quát bất kỳ ngày nào
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
      setState(() {
        _selectedDate = picked;
        _focusedDay =
            picked; // Cập nhật luôn focus để hiển thị tuần chứa ngày mới
      });
    }
  }

  // Hàm giả lập dữ liệu (Giữ nguyên)
  List<Event> _getEventsForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final todayKey =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    if (dateKey == todayKey) {
      return [
        Event(
          title: 'Team Sync Meeting',
          startTime: '09:00',
          endTime: '10:00',
          location: 'Zoom Meeting',
          colorTag: const Color(0xFF6366F1),
        ),
        Event(
          title: 'Review Project Alpha',
          startTime: '10:30',
          endTime: '11:30',
          location: 'Room 302',
          colorTag: const Color(0xFFEC4899),
        ),
        Event(
          title: 'Lunch with Client',
          startTime: '12:00',
          endTime: '13:00',
          location: 'Downtown Cafe',
          colorTag: const Color(0xFF10B981),
        ),
        Event(
          title: 'Code Review',
          startTime: '14:00',
          endTime: '15:30',
          location: null,
          colorTag: const Color(0xFFF59E0B),
        ),
      ];
    }
    // Mở rộng logic giả lập cho các ngày khác nếu muốn test
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Event> events = _getEventsForDate(_selectedDate);
    final List<DateTime> weekDays = _getWeekDays(_focusedDay);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Schedule",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate, // Nút lịch tắt nhanh
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. THANH CHỌN THÁNG / TUẦN (MỚI THÊM) ---
          _buildMonthNavigator(theme, colorScheme),

          const SizedBox(height: 12),

          // --- 2. THANH CHỌN NGÀY TRONG TUẦN ---
          _buildWeekSelector(weekDays, theme, colorScheme),

          const SizedBox(height: 16),

          // --- 3. TIÊU ĐỀ NGÀY ĐÃ CHỌN ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateHeader(_selectedDate),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onBackground,
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
                    '${events.length} Events',
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

          // --- 4. DANH SÁCH SỰ KIỆN ---
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState(theme, colorScheme)
                : _buildTimeline(events, theme, colorScheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
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

  // --- WIDGET MỚI: THANH ĐIỀU HƯỚNG ---
  Widget _buildMonthNavigator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút Previous Week
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
            splashRadius: 24,
          ),

          // Tiêu đề Tháng/Năm (Bấm để mở DatePicker)
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

          // Nút Next Week
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
            onTap: () {
              setState(() {
                _selectedDate = day;
                // Nếu chọn ngày thuộc tuần khác, cập nhật luôn focus (nhưng trong logic trên
                // tuần hiển thị dựa trên _focusedDay, nếu chọn ngày nằm ngoài tuần này,
                // bạn có thể gọi _changeFocusedDate(day) để nhảy tới tuần mới đó)
                _changeFocusedDate(day);
              });
            },
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
                      : colorScheme.outline.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.secondary.withOpacity(0.3),
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
                          ? colorScheme.onSecondary.withOpacity(0.8)
                          : colorScheme.onSurface.withOpacity(0.6),
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

  // Các widget buildTimeline, buildEventCard, EmptyState giữ nguyên như code cũ
  // (Tôi sẽ copy lại để code chạy được ngay)...

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
                          color: colorScheme.onSurface.withOpacity(0.5),
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
                    color: event.colorTag.withOpacity(0.3),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (event.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  event.location!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
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
              size: 64, color: colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No events scheduled',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
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
