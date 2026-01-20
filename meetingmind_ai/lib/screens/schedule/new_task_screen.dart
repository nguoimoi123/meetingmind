import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:meetingmind_ai/services/reminder_service.dart';
import 'package:meetingmind_ai/services/notification_service.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/models/event_model.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  late String _userId;
  bool _isLoading = false;

  // --- PALETTE MÀU SẮC ---
  static const Color _vibrantBlue = Color(0xFF2962FF);
  static const Color _softGrey = Color(0xFFF5F7FA);

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

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context)
              .copyWith(colorScheme: ColorScheme.light(primary: _vibrantBlue)),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context)
              .copyWith(colorScheme: ColorScheme.light(primary: _vibrantBlue)),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _startTime = pickedTime;
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context)
              .copyWith(colorScheme: ColorScheme.light(primary: _vibrantBlue)),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Date, Start and End time')),
      );
      return;
    }

    final startFull = _combineDateTime(_startTime!);
    final endFull = _combineDateTime(_endTime!);

    if (endFull.isBefore(startFull) || endFull.isAtSameMomentAs(startFull)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ReminderService.createTask(
        userId: _userId,
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        startTime: startFull,
        endTime: endFull,
      );

      await NotificationService().requestPermissions();
      final notificationId = startFull.millisecondsSinceEpoch ~/ 1000;

      await NotificationService().scheduleNotification(
        context: context,
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
          const SnackBar(
            content: Text('Task created & reminder set!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Task',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)], // Placeholder to balance title
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  24, 0, 24, 100), // Padding bottom cho FAB
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // --- TITLE INPUT (NotebookLM Style - Big & Bold) ---
                    Text(
                      'What needs to be done?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _vibrantBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title your task',
                        hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 32, thickness: 1),

                    // --- LOCATION INPUT ---
                    Text(
                      'Location (Optional)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: _softGrey,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: colorScheme.onSurface.withOpacity(0.5),
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                hintText: 'Where?',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- DATE & TIME SELECTORS ---
                    Text(
                      'Schedule',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildModernSelector(
                      label: 'Date',
                      value: _selectedDate != null
                          ? dateFormat.format(_selectedDate!)
                          : null,
                      icon: Icons.calendar_month_rounded,
                      onTap: _selectDate,
                      colorScheme: colorScheme,
                      isFilled: _selectedDate != null,
                    ),

                    const SizedBox(height: 16),

                    _buildModernSelector(
                      label: 'Start Time',
                      value: _startTime != null
                          ? timeFormat.format(DateTime(
                              2023, 1, 1, _startTime!.hour, _startTime!.minute))
                          : null,
                      icon: Icons.play_arrow_rounded,
                      onTap: _selectStartTime,
                      colorScheme: colorScheme,
                      isFilled: _startTime != null,
                    ),

                    const SizedBox(height: 16),

                    _buildModernSelector(
                      label: 'End Time',
                      value: _endTime != null
                          ? timeFormat.format(DateTime(
                              2023, 1, 1, _endTime!.hour, _endTime!.minute))
                          : null,
                      icon: Icons.flag_rounded,
                      onTap: _selectEndTime,
                      colorScheme: colorScheme,
                      isFilled: _endTime != null,
                    ),
                  ],
                ),
              ),
            ),

            // --- FLOATING SAVE BUTTON ---
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vibrantBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: _vibrantBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Create Task',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSelector({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isFilled,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFilled ? Colors.white : _softGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isFilled ? _vibrantBlue.withOpacity(0.2) : Colors.transparent,
            width: 1,
          ),
          boxShadow: isFilled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isFilled
                    ? _vibrantBlue.withOpacity(0.1)
                    : colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isFilled
                    ? _vibrantBlue
                    : colorScheme.onSurface.withOpacity(0.4),
                size: 24,
              ),
            ),
            const SizedBox(width: 20),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Select time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isFilled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
