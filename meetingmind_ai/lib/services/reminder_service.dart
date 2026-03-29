import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/event_model.dart';
import 'api_auth_headers.dart';

class ReminderService {
  static String get _baseUrl => apiBaseUrl;

  static Future<void> createTask({
    required String userId,
    required String title,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final body = {
      'user_id': userId,
      'title': title,
      'location': location,
      'remind_start': startTime.toIso8601String(),
      'remind_end': endTime.toIso8601String(),
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/reminder/add'),
      headers: await ApiAuthHeaders.build(json: true),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Create task failed: ${res.statusCode}');
    }
  }

  static Future<List<Event>> fetchEvents({
    required String userId,
    required DateTime date,
  }) async {
    final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final url = Uri.parse(
      '$_baseUrl/reminder/day?user_id=$userId&date=$formatted&tz_offset=$tzOffset',
    );

    final res = await http.get(
      url,
      headers: await ApiAuthHeaders.build(),
    );

    if (res.statusCode != 200) {
      throw Exception('Fetch failed: ${res.statusCode}');
    }

    final data = json.decode(res.body) as List<dynamic>;
    print('Fetched events: $data');
    return data.map((item) => Event.fromJson(item)).toList();
  }

  static Future<void> deleteReminder({
    required String userId,
    required String reminderId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/reminder/delete/$reminderId');
      final response = await http.delete(
        url,
        headers: await ApiAuthHeaders.build(json: true),
        body: jsonEncode({
          'user_id': userId,
          'id': reminderId,
        }),
      );

      if (response.statusCode == 200) {
        print('Reminder deleted successfully');
        return;
      }
      throw Exception('Failed to delete reminder: ${response.statusCode}');
    } catch (e) {
      print('Error deleting reminder: $e');
      throw Exception('Error connecting to server');
    }
  }
}
