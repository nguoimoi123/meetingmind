import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:meetingmind_ai/services/reminder_service.dart';
import 'package:meetingmind_ai/services/notification_service.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/models/event_model.dart'; // <--- THÊM IMPORT NÀY

class NewTaskScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialLocation;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;

  const NewTaskScreen({
    super.key,
    this.initialTitle,
    this.initialLocation,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  // Các biến lưu trữ thời gian
  DateTime? _startTime;
  DateTime? _endTime;

  // User ID động
  late String _userId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle?.trim() ?? '';
    _locationController.text = widget.initialLocation?.trim() ?? '';
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
    if (_startTime != null && _endTime == null) {
      _endTime = _startTime!.add(const Duration(hours: 1));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<AuthProvider>();
      if (userProvider.userId != null) {
        setState(() {
          _userId = userProvider.userId!;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- HÀM CHECK TRÙNG GIỜ ---
  bool _isOverlapping(
    DateTime newStart,
    DateTime newEnd,
    String oldStartStr,
    String oldEndStr,
  ) {
    final partsStart = oldStartStr.split(':');
    final partsEnd = oldEndStr.split(':');

    if (partsStart.length != 2 || partsEnd.length != 2) return false;

    final oldStartHour = int.parse(partsStart[0]);
    final oldStartMinute = int.parse(partsStart[1]);
    final oldEndHour = int.parse(partsEnd[0]);
    final oldEndMinute = int.parse(partsEnd[1]);

    // Tái tạo DateTime cũ cùng ngày với ngày mới đang chọn
    final oldStart = DateTime(
      newStart.year,
      newStart.month,
      newStart.day,
      oldStartHour,
      oldStartMinute,
    );
    final oldEnd = DateTime(
      newStart.year,
      newStart.month,
      newStart.day,
      oldEndHour,
      oldEndMinute,
    );

    // Công thức check giao thoa: (NewStart < OldEnd) && (NewEnd > OldStart)
    return newStart.isBefore(oldEnd) && newEnd.isAfter(oldStart);
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = finalDateTime;
        if (_endTime == null || _endTime!.isBefore(_startTime!)) {
          _endTime = _startTime!.add(const Duration(hours: 1));
        }
      } else {
        _endTime = finalDateTime;
      }
    });
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end time')),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before start time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. LẤY DANH SÁCH LỊCH TRONG NGÀY ĐỂ CHECK TRÙNG
      // Chỉ check nếu có ngày giờ chọn
      if (_startTime != null) {
        final existingEvents = await ReminderService.fetchEvents(
          userId: _userId,
          date: _startTime!,
        );

        Event? conflictingEvent;

        for (var event in existingEvents) {
          if (_isOverlapping(
              _startTime!, _endTime!, event.startTime, event.endTime)) {
            conflictingEvent = event;
            break; // Chỉ cần tìm 1 cái bị trùng
          }
        }

        // Nếu có trùng -> Hiện Dialog
        if (conflictingEvent != null) {
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Trùng lịch trình'),
              content: Text(
                  'Đã có sự kiện "${conflictingEvent?.title}" vào khung giờ này.\nBạn có muốn thay thế sự kiện đó không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Thay thế'),
                ),
              ],
            ),
          );

          // Nếu người dùng bấm Hủy -> Dừng lại
          if (shouldProceed != true) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            return;
          }

          // Nếu đồng ý thay thế -> Xóa sự kiện cũ (Cả Database và Notification)
          print("Deleting conflicting event: ${conflictingEvent.id}");
          await ReminderService.deleteReminder(
            userId: _userId,
            reminderId: conflictingEvent.id,
          );

          // Cần hủy thông báo của sự kiện cũ
          final parts = conflictingEvent.startTime.split(':');
          if (parts.length == 2) {
            final h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final oldDateTime = DateTime(
                _startTime!.year, _startTime!.month, _startTime!.day, h, m);
            final oldNotificationId =
                oldDateTime.millisecondsSinceEpoch ~/ 1000;
            await NotificationService().cancelNotification(oldNotificationId);
          }
        }
      }

      // 2. TẠO SỰ KIỆN MỚI
      await ReminderService.createTask(
        userId: _userId,
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        startTime: _startTime!,
        endTime: _endTime!,
      );

      // 3. ĐẶT THÔNG BÁO MỚI
      await NotificationService().requestPermissions();
      final notificationId = _startTime!.millisecondsSinceEpoch ~/ 1000;

      await NotificationService().scheduleNotification(
        context: context, // <--- Truyền context vào đây
        id: notificationId,
        title: _titleController.text.trim(),
        body: _locationController.text.trim().isEmpty
            ? 'Event starting now!'
            : 'at ${_locationController.text.trim()}',
        scheduledTime: _startTime!,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created & reminder set!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFormat = DateFormat('HH:mm, dd MMM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _submitTask,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What needs to be done?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Task Title',
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Location (Optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Where?',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: colorScheme.outline),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Time',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeCard(
                title: 'Start Time',
                time: _startTime,
                format: timeFormat,
                icon: Icons.play_arrow,
                onTap: () => _selectDateTime(isStart: true),
                colorScheme: colorScheme,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTimeCard(
                title: 'End Time',
                time: _endTime,
                format: timeFormat,
                icon: Icons.flag,
                onTap: () => _selectDateTime(isStart: false),
                colorScheme: colorScheme,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required DateTime? time,
    required DateFormat format,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorScheme.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null ? format.format(time) : 'Select time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: time != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
