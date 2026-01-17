import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'newtask.dart';

// Model dữ liệu sự kiện
class Event {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String? location;
  final Color colorTag;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.colorTag,
  });

  // Factory constructor để parse từ JSON trả về từ API
  factory Event.fromJson(Map<String, dynamic> json) {
    // Parse chuỗi thời gian từ API
    DateTime start = DateTime.parse(json['remind_start']).toLocal();
    DateTime end = DateTime.parse(json['remind_end']).toLocal();

    // Format thời gian sang định dạng HH:mm (ví dụ: 14:30)
    final timeFormat = DateFormat('HH:mm');

    // Danh sách màu sắc để random (đảm bảo đẹp mắt)
    final List<Color> availableColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
    ];

    // Logic chọn màu random
    final random = Random();
    final Color randomColor =
        availableColors[random.nextInt(availableColors.length)];

    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      startTime: timeFormat.format(start),
      endTime: timeFormat.format(end),
      location: json['location'],
      colorTag: randomColor,
    );
  }
}

class ScheduleTasksScreen extends StatefulWidget {
  const ScheduleTasksScreen({super.key});

  @override
  State<ScheduleTasksScreen> createState() => _ScheduleTasksScreenState();
}

class _ScheduleTasksScreenState extends State<ScheduleTasksScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedDay;

  // Future để chứa dữ liệu từ API
  late Future<List<Event>> _eventsFuture;

  // ID người dùng (Cố định theo ví dụ, trong app thật lấy từ Authentication)
  final String _currentUserId = "6965304ba729391015e6d079";

  // URL API mới
  final String _baseUrl = "http://127.0.0.1:5001/reminder/day";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _focusedDay = now;
    // Tải dữ liệu ban đầu
    _eventsFuture = _fetchEvents(_selectedDate);
  }

  // Hàm gọi API (Đã cập nhật theo API mới)
  Future<List<Event>> _fetchEvents(DateTime date) async {
    try {
      // Format ngày theo định dạng YYYY-MM-DD (Ví dụ: 2026-01-18)
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Tạo URL với tham số user_id và date
      final Uri url =
          Uri.parse('$_baseUrl?user_id=$_currentUserId&date=$formattedDate');

      print("🔗 Fetching URL: $url");

      final response = await http.get(url);

      print("🔎 Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print("✅ Found ${data.length} events.");

        // Map dữ liệu JSON thành danh sách các đối tượng Event
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        // Nếu server trả lỗi, throw exception để FutureBuilder bắt lỗi
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      // In log lỗi để debug
      print("Error fetching events: $e");
      throw Exception('Error connecting to server');
    }
  }

  // Hàm reset dữ liệu khi đổi ngày
  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _focusedDay = newDate;
      // Gọi lại API cho ngày mới
      _eventsFuture = _fetchEvents(_selectedDate);
    });
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

    // Nếu result là true (nghĩa là đã tạo task thành công),
    // ta sẽ gọi lại API để tải lại danh sách của ngày hiện tại
    if (result == true && mounted) {
      setState(() {
        _eventsFuture = _fetchEvents(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

          // Header hiển thị ngày và số lượng sự kiện (sẽ update khi có dữ liệu)
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

          // --- 4. DANH SÁCH SỰ KIỆN (DÙNG FUTURE BUILDER) ---
          Expanded(
            child: FutureBuilder<List<Event>>(
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
            onTap: () => _updateSelectedDate(day), // Cập nhật ngày và gọi API
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
                  color: event.colorTag, // Sử dụng màu random từ API
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

  Widget _buildErrorState(
      ThemeData theme, ColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 64, color: colorScheme.error.withOpacity(0.5)),
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
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _eventsFuture = _fetchEvents(_selectedDate);
              });
            },
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
