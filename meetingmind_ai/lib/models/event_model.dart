import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    // Parse chuỗi thời gian từ API
    String startStr = json['remind_start'];
    String endStr = json['remind_end'];

    // --- SỬA: ÉP THÊM CHỮ 'Z' VÀO CUỐI CHUỖI NẾU THIẾU ---
    // Điều này bảo Flutter rằng thời gian này là UTC
    if (!startStr.endsWith('Z') && !startStr.contains('+')) {
      startStr += 'Z';
    }
    if (!endStr.endsWith('Z') && !endStr.contains('+')) {
      endStr += 'Z';
    }
    // ------------------------------------------------

    DateTime start = DateTime.parse(startStr).toLocal();
    DateTime end = DateTime.parse(endStr).toLocal();

    // Format thời gian sang định dạng HH:mm
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
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      startTime: timeFormat.format(start),
      endTime: timeFormat.format(end),
      location: json['location'],
      colorTag: randomColor,
    );
  }
}
