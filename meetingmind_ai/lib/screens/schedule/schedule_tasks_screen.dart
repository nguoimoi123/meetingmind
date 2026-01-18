import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'newtask.dart'; // Đảm bảo import file NewTaskScreen đã có nút delete

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

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime start = DateTime.parse(json['remind_start']).toLocal();
    DateTime end = DateTime.parse(json['remind_end']).toLocal();
    final timeFormat = DateFormat('HH:mm');

    final List<Color> availableColors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];

    final random = Random();
    final Color randomColor =
        availableColors[random.nextInt(availableColors.length)];

    return Event(
      id: json['id'] ?? '', // Đảm bảo lấy ID từ API
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

  late Future<List<Event>> _eventsFuture;

  final String _currentUserId = "6965304ba729391015e6d079";
  final String _baseUrl = "${dotenv.env['API_BASE_URL']}/reminder/day";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _focusedDay = now;
    _eventsFuture = _fetchEvents(_selectedDate);
  }

  Future<List<Event>> _fetchEvents(DateTime date) async {
    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final Uri url =
          Uri.parse('$_baseUrl?user_id=$_currentUserId&date=$formattedDate');

      print("🔗 Fetching URL: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching events: $e");
      throw Exception('Error connecting to server');
    }
  }

  // ---------------------------------------------------------
  // HÀM XOÁ SỰ KIỆN (DELETE)
  // ---------------------------------------------------------
  Future<void> _deleteEvent(String eventId) async {
    // Lấy API_BASE_URL từ env để ghép đúng đường dẫn xoá
    // Mẫu API: DELETE http://127.0.0.1:5001/reminder/{id}
    final String? apiBase = dotenv.env['API_BASE_URL'];
    if (apiBase == null) return;

    final Uri url = Uri.parse('$apiBase/reminder/$eventId');

    try {
      print("🗑️ Deleting URL: $url");
      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Xoá thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã xoá sự kiện'), backgroundColor: Colors.green),
          );
          // Tải lại danh sách
          setState(() {
            _eventsFuture = _fetchEvents(_selectedDate);
          });
        }
      } else {
        print("Failed to delete: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi xoá: ${response.statusCode}'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Error deleting: $e");
    }
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _focusedDay = newDate;
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

  // -------------------------
  // HÀM MỞ MÀN HÌNH TASK (CÓ THỂ TẠO MỚI HOẶC SỬA/XOÁ)
  // -------------------------
  Future<void> _openTaskScreen({String? taskId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // Truyền taskId vào đây. Nếu null -> Tạo mới. Nếu có -> Sửa/Xoá
        builder: (context) => NewTaskScreen(taskId: taskId),
      ),
    );

    // Nếu result là true (tạo/sửa/xoá thành công), tải lại danh sách
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
        onPressed: () => _openTaskScreen(), // Gọi hàm chung không có ID
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
                  child: GestureDetector(
                    onTap: () =>
                        _openTaskScreen(taskId: event.id), // Truyền ID để sửa
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: event.colorTag,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openTaskScreen(taskId: event.id);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(event.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Sửa'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xoá'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (event.location != null &&
                              event.location!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.location!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorState(
      ThemeData theme, ColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể tải dữ liệu',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _eventsFuture = _fetchEvents(_selectedDate);
              });
            },
            child: const Text('Thử lại'),
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
          Icon(
            Icons.event_note,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có sự kiện nào',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm sự kiện mới để bắt đầu',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc muốn xoá sự kiện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEvent(eventId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, d MMM').format(date);
    }
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
