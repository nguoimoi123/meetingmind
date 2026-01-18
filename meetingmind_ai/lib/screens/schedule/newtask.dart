import 'dart:convert'; // <--- Cần thiết để encode JSON
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // <--- Import thư viện http

class NewTaskScreen extends StatefulWidget {
  final String? taskId;

  const NewTaskScreen({super.key, this.taskId});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // ID người dùng (Thường lấy từ SharedPreferences/Hive/Database sau khi login)
  // Ở đây mình hardcode theo ví dụ của bạn để demo
  String _currentUserId = "6965304ba729391015e6d079";

  // Biến để kiểm tra trạng thái đang gọi API
  bool _isLoading = false;

  // URL API
  final String _apiUrl = "http://localhost:5001/reminder/add";

  // -------------------------
  // STEP 1: PICK DATE
  // -------------------------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // -------------------------
  // STEP 2: PICK START TIME
  // -------------------------
  Future<void> _pickStartTime() async {
    if (_selectedDate == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        _endTime = null; // reset end time khi start thay đổi
      });
    }
  }

  // -------------------------
  // STEP 3: PICK END TIME
  // -------------------------
  Future<void> _pickEndTime() async {
    if (_selectedDate == null || _startTime == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime!,
    );

    if (picked != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = picked.hour * 60 + picked.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
          ),
        );
        return;
      }

      setState(() {
        _endTime = picked;
      });
    }
  }

  // -------------------------
  // UTIL: COMBINE DATE + TIME
  // -------------------------
  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // -------------------------
  // FORM VALIDATION
  // -------------------------
  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty &&
      _selectedDate != null &&
      _startTime != null &&
      _endTime != null;

  // -------------------------
  // SUBMIT (CALL API)
  // -------------------------
  void _submit() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final startDateTime = _combine(_selectedDate!, _startTime!);
    final endDateTime = _combine(_selectedDate!, _endTime!);

    // Tạo body khớp với format của curl
    final Map<String, dynamic> payload = {
      "user_id": _currentUserId,
      "title": _titleController.text.trim(),
      "location": _locationController.text.trim(),
      "remind_start": startDateTime.toIso8601String(),
      "remind_end": endDateTime.toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo task thành công!')),
          );
          Navigator.pop(
              context, true); // Quay về màn hình trước và báo thành công
        }
      } else {
        // Lỗi từ Server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Lỗi server: ${response.statusCode} - ${response.body}')),
          );
        }
      }
    } catch (e) {
      // Lỗi kết nối (ví dụ không bật localhost:5001)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
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
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITLE
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter task title',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // LOCATION
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
              ),
            ),
            const SizedBox(height: 32),

            // DATE
            _buildPickerTile(
              icon: Icons.calendar_today,
              title: _selectedDate == null
                  ? 'Select date'
                  : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              onTap: _pickDate,
            ),

            // START TIME
            _buildPickerTile(
              icon: Icons.schedule,
              title: _startTime == null
                  ? 'Select start time'
                  : _startTime!.format(context),
              enabled: _selectedDate != null,
              onTap: _pickStartTime,
            ),

            // END TIME
            _buildPickerTile(
              icon: Icons.schedule_outlined,
              title: _endTime == null
                  ? 'Select end time'
                  : _endTime!.format(context),
              enabled: _startTime != null,
              onTap: _pickEndTime,
            ),

            const SizedBox(height: 32),

            // SUMMARY
            if (_isFormValid)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${DateFormat('dd/MM/yyyy').format(_selectedDate!)} '
                        '• ${_startTime!.format(context)} → ${_endTime!.format(context)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      // SUBMIT BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: (_isFormValid && !_isLoading) ? _submit : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Create Task',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // -------------------------
  // REUSABLE TILE
  // -------------------------
  Widget _buildPickerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      enabled: enabled,
      onTap: enabled ? onTap : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}
