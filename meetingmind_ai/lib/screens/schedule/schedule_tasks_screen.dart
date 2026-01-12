import 'package:flutter/material.dart';

class ScheduleTasksScreen extends StatelessWidget {
  const ScheduleTasksScreen({super.key});

  // Widget helper để tạo một thẻ sự kiện (blue card)
  Widget _buildEventCard(
      String title, String time, String location, BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(left: 32.0, right: 16.0, top: 8.0, bottom: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(time,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          if (location.isNotEmpty)
            Text(location,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  // Widget helper để tạo một thẻ công việc (white card with left border)
  Widget _buildTaskCard(String title, String time, BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(left: 32.0, right: 16.0, top: 8.0, bottom: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border:
            Border(left: BorderSide(color: colorScheme.secondary, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(time, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Schedule", style: theme.textTheme.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Phần tiêu đề ngày tháng ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Schedule",
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tuesday, 26 Nov",
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            // --- Phần Timeline ---
            _buildTimeline(context),

            // --- Phần "Upcoming Tasks" ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Tasks',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: false,
                    onChanged: (bool? value) {},
                    title: Text('Review Marketing Proposal',
                        style: theme.textTheme.bodyLarge),
                    secondary: const Icon(Icons.description),
                  ),
                  CheckboxListTile(
                    value: false,
                    onChanged: (bool? value) {},
                    title: Text('Submit expense report',
                        style: theme.textTheme.bodyLarge),
                    secondary: const Icon(Icons.receipt_long),
                  ),
                  CheckboxListTile(
                    value: true,
                    onChanged: (bool? value) {},
                    title: Text(
                      'Finalize Q3 presentation slides',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color:
                            theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                      ),
                    ),
                    secondary: const Icon(Icons.slideshow),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add new task/event
        },
        backgroundColor: colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget để xây dựng toàn bộ timeline
  Widget _buildTimeline(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cột thời gian
          SizedBox(
            width: 60,
            child: Column(
              children: [
                _buildTimeSlot('09 AM', theme),
                _buildTimeSlot('10 AM', theme),
                _buildTimeSlot('11 AM', theme),
                _buildTimeSlot('12 PM', theme),
                _buildTimeSlot('01 PM', theme),
                _buildTimeSlot('02 PM', theme),
              ],
            ),
          ),
          // Đường kẻ dọc
          VerticalDivider(
            width: 1.5,
            color: theme.dividerColor,
            thickness: 1.5,
          ),
          // Cột sự kiện/công việc
          Expanded(
            child: Stack(
              children: [
                // Các sự kiện và công việc
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16 * 4), // Spacer for 9 AM
                    _buildEventCard('Project Sync', '10:00 - 11:00 AM',
                        'Conference Room 4', context),
                    const SizedBox(height: 16 * 1.5), // Spacer
                    _buildTaskCard(
                        'Follow up with Design Team', '11:30 AM', context),
                    const SizedBox(height: 16 * 2), // Spacer
                    _buildTaskCard(
                        'Prepare Q4 Report Draft', '1:00 PM', context),
                    const SizedBox(height: 16 * 0.5), // Spacer
                    _buildEventCard('Strategy Meeting', '2:00 PM - 3:30 PM',
                        'Virtual', context),
                  ],
                ),
                // Chỉ thị thời gian hiện tại (đặt ở vị trí 10:30 AM)
                Positioned(
                  top: 16 * 4.0 + 16.0 * 0.5, // Vị trí của 10:30 AM
                  left: -10,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper để tạo một ô thời gian
  Widget _buildTimeSlot(String time, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        time,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        textAlign: TextAlign.right,
      ),
    );
  }
}
