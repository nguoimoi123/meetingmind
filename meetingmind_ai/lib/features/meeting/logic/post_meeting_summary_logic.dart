import 'package:meetingmind_ai/models/meeting_summary.dart';

class PostMeetingSummaryLogic {
  static Set<String> extractSpeakerIds(MeetingSummary? summary) {
    final transcript = summary?.fullTranscript ?? '';
    if (transcript.isEmpty) return {};

    final lines = transcript.split('\n');
    final speakers = <String>{};
    for (final line in lines) {
      final match = RegExp(r'^\s*([^:]{1,40})\s*:').firstMatch(line);
      if (match != null) {
        final speaker = match.group(1)?.trim();
        if (speaker != null && speaker.isNotEmpty) {
          speakers.add(speaker);
        }
      }
    }
    return speakers;
  }

  static bool hasScheduleHints(MeetingSummary? summary) {
    if (summary == null) return false;
    final items = summary.actionItems;
    if (items.isEmpty) return false;

    final scheduleRegex = RegExp(
      r'(\b\d{1,2}[:.]\d{2}\b|\b\d{1,2}\s*(am|pm)\b|\bng\.?\s*\d{1,2}\b|\bngày\b|\bthứ\b|\btuần\b|\btháng\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b)',
      caseSensitive: false,
    );

    return items.any((item) => scheduleRegex.hasMatch(item));
  }

  static Map<String, dynamic> buildScheduleSuggestion(MeetingSummary? summary) {
    final items = summary?.actionItems ?? [];
    final scheduleRegex = RegExp(
      r'(\b\d{1,2}[:.]\d{2}\b|\b\d{1,2}\s*(am|pm)\b|\bng\.?\s*\d{1,2}\b|\bngày\b|\bthứ\b|\btuần\b|\btháng\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b)',
      caseSensitive: false,
    );

    final target = items.firstWhere(
      (item) => scheduleRegex.hasMatch(item),
      orElse: () => items.isNotEmpty ? items.first : '',
    );

    final title = target.isNotEmpty ? target : 'New Task';
    final locationMatch =
        RegExp(r'(?:tại|ở)\s+([^,.;]+)', caseSensitive: false).firstMatch(target);
    final location = locationMatch?.group(1)?.trim();

    DateTime? date;
    DateTime? timeOnly;

    final dateMatch = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})').firstMatch(target);
    if (dateMatch != null) {
      final day = int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      var year = int.parse(dateMatch.group(3)!);
      if (year < 100) year += 2000;
      date = DateTime(year, month, day);
    } else {
      final shortDateMatch = RegExp(r'ng\.?\s*(\d{1,2})/(\d{1,2})').firstMatch(target);
      if (shortDateMatch != null) {
        final day = int.parse(shortDateMatch.group(1)!);
        final month = int.parse(shortDateMatch.group(2)!);
        final now = DateTime.now();
        date = DateTime(now.year, month, day);
      }
    }

    final timeMatch = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(target);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      final now = DateTime.now();
      timeOnly = DateTime(now.year, now.month, now.day, hour, minute);
    } else {
      final ampmMatch =
          RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false).firstMatch(target);
      if (ampmMatch != null) {
        var hour = int.parse(ampmMatch.group(1)!);
        final meridian = ampmMatch.group(2)!.toLowerCase();
        if (meridian == 'pm' && hour < 12) hour += 12;
        if (meridian == 'am' && hour == 12) hour = 0;
        final now = DateTime.now();
        timeOnly = DateTime(now.year, now.month, now.day, hour, 0);
      }
    }

    DateTime? startTime;
    if (date != null && timeOnly != null) {
      startTime = DateTime(
        date.year,
        date.month,
        date.day,
        timeOnly.hour,
        timeOnly.minute,
      );
    }

    DateTime? endTime;
    if (startTime != null) {
      endTime = startTime.add(const Duration(hours: 1));
    }

    return {
      'title': title,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  static String buildReportContent(MeetingSummary? summary) {
    final buffer = StringBuffer();
    buffer.writeln('Meeting Report');
    buffer.writeln('');
    buffer.writeln('Summary:');
    buffer.writeln(summary?.summary ?? '');
    buffer.writeln('');
    buffer.writeln('Action Items:');
    if (summary?.actionItems.isNotEmpty == true) {
      for (final item in summary!.actionItems) {
        buffer.writeln('- $item');
      }
    } else {
      buffer.writeln('- None');
    }
    buffer.writeln('');
    buffer.writeln('Key Decisions:');
    if (summary?.keyDecisions.isNotEmpty == true) {
      for (final item in summary!.keyDecisions) {
        buffer.writeln('- $item');
      }
    } else {
      buffer.writeln('- None');
    }
    buffer.writeln('');
    buffer.writeln('Full Transcript:');
    buffer.writeln(summary?.fullTranscript ?? '');
    return buffer.toString();
  }
}
