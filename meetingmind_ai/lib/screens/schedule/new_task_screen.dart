import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:meetingmind_ai/services/reminder_service.dart';
import 'package:meetingmind_ai/services/notification_service.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  // Các biến lưu trữ thời gian
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // User ID động
  late String _userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<AuthProvider>();
      if (userProvider.userId != null) {
        setState(() {
          _userId = userProvider.userId!;
        });
      } else {
        setState(() {
          _userId = 'unknown_user';
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

  // --- HÀM CHỌN NGÀY ---
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
        _startTime = null;
        _endTime = null;
      });
    }
  }

  // --- HÀM CHỌN GIỜ BẮT ĐẦU ---
  Future<void> _selectStartTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _startTime = pickedTime;
        // Tự động set End Time = Start Time + 1 giờ nếu chưa chọn
        if (_endTime == null ||
            _endTime!.hour < _startTime!.hour ||
            (_endTime!.hour == _startTime!.hour &&
                _endTime!.minute < _startTime!.minute)) {
          _endTime = TimeOfDay(
            hour: (_startTime!.hour + 1) % 24,
            minute: _startTime!.minute,
          );
        }
      });
    }
  }

  // --- HÀM CHỌN GIỜ KẾT THÚC ---
  Future<void> _selectEndTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time first')),
      );
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime!,
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  // --- HÀM GỘP DỮ LIỆU ĐỂ GỬI API ---
  DateTime _combineDateTime(TimeOfDay time) {
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra logic thời gian
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Date, Start and End time')),
      );
      return;
    }

    // Chuyển đổi thành full DateTime để so sánh
    final startFull = _combineDateTime(_startTime!);
    final endFull = _combineDateTime(_endTime!);

    if (endFull.isBefore(startFull) || endFull.isAtSameMomentAs(startFull)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API Service (đã xử lý format ngày giờ bên trong)
      await ReminderService.createTask(
        userId: _userId,
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        startTime: startFull,
        endTime: endFull,
      );

      // Xử lý Notification
      await NotificationService().requestPermissions();
      final notificationId = startFull.millisecondsSinceEpoch ~/ 1000;

      await NotificationService().scheduleNotification(
        id: notificationId,
        title: _titleController.text.trim(),
        body: _locationController.text.trim().isEmpty
            ? 'Event starting now!'
            : 'at ${_locationController.text.trim()}',
        scheduledTime: startFull,
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
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

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
              // 1. TITLE
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

              // 2. LOCATION (ĐÃ SỬA: BỔ IGNORE POINTER ĐỂ CÓ THỂ NHẬP LIỆU)
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

              // --- PHẦN THỜI GIAN ---

              // 3. DATE (NGÀY)
              Text(
                'Date',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectorCard(
                title: 'Select Date',
                value: _selectedDate != null
                    ? dateFormat.format(_selectedDate!)
                    : null,
                icon: Icons.calendar_today,
                onTap: _selectDate,
                colorScheme: colorScheme,
                theme: theme,
              ),
              const SizedBox(height: 24),

              // 4. START TIME (GIỜ BẮT ĐẦU)
              Text(
                'Start Time',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectorCard(
                title: 'Select Start Time',
                value: _startTime != null
                    ? timeFormat.format(DateTime(
                        2023, 1, 1, _startTime!.hour, _startTime!.minute))
                    : null,
                icon: Icons.play_arrow,
                onTap: _selectStartTime,
                colorScheme: colorScheme,
                theme: theme,
              ),
              const SizedBox(height: 24),

              // 5. END TIME (GIỜ KẾT THÚC)
              Text(
                'End Time',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectorCard(
                title: 'Select End Time',
                value: _endTime != null
                    ? timeFormat.format(
                        DateTime(2023, 1, 1, _endTime!.hour, _endTime!.minute))
                    : null,
                icon: Icons.flag,
                onTap: _selectEndTime,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper để hiển thị thẻ chọn thời gian
  Widget _buildSelectorCard({
    required String title,
    required String? value,
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
                    value ?? 'Not set',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: value != null
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
