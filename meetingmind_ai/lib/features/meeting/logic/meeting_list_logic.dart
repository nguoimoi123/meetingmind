import 'package:flutter/material.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';

class MeetingListLogic {
  static List<String> collectTags(List<Meeting> meetings) {
    final tags = <String>{};
    for (final meeting in meetings) {
      for (final tag in meeting.tags) {
        final clean = tag.trim();
        if (clean.isNotEmpty) {
          tags.add(clean);
        }
      }
    }
    final list = tags.toList()..sort();
    return list;
  }

  static List<Meeting> filterMeetings({
    required List<Meeting> meetings,
    required String searchQuery,
    String? selectedTag,
  }) {
    return meetings.where((meeting) {
      final matchesQuery = meeting.title
          .toLowerCase()
          .contains(searchQuery.trim().toLowerCase());
      final matchesTag =
          selectedTag == null || meeting.tags.contains(selectedTag);
      return matchesQuery && matchesTag;
    }).toList();
  }

  static Meeting copyWithTags(Meeting meeting, List<String> tags) {
    return Meeting(
      id: meeting.id,
      title: meeting.title,
      subtitle: meeting.subtitle,
      date: meeting.date,
      status: meeting.status,
      time: meeting.time,
      participants: meeting.participants,
      tags: tags,
      contextFile: meeting.contextFile,
      contextText: meeting.contextText,
    );
  }

  static MeetingStatusPresentation statusFor(Meeting meeting) {
    if (meeting.status == 'Completed' || meeting.date.isBefore(DateTime.now())) {
      return const MeetingStatusPresentation(
        color: Color(0xFF16A34A),
        icon: Icons.check_circle_rounded,
        label: 'Done',
      );
    }

    if (meeting.status == 'Live') {
      return const MeetingStatusPresentation(
        color: Color(0xFFDC2626),
        icon: Icons.fiber_manual_record_rounded,
        label: 'Live',
      );
    }

    return const MeetingStatusPresentation(
      color: Color(0xFFF59E0B),
      icon: Icons.upcoming_rounded,
      label: 'Upcoming',
    );
  }
}

class MeetingStatusPresentation {
  final Color color;
  final IconData icon;
  final String label;

  const MeetingStatusPresentation({
    required this.color,
    required this.icon,
    required this.label,
  });
}
