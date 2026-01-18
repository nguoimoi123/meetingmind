import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReminderService {
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<void> createTask({
    required String userId,
    required String title,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final body = {
      "user_id": userId,
      "title": title,
      "location": location,
      "remind_start": startTime.toIso8601String(),
      "remind_end": endTime.toIso8601String(),
    };

    final res = await http.post(
      Uri.parse("$_baseUrl/reminder/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Create task failed: ${res.statusCode}");
    }
  }

  static Future<List<Event>> fetchEvents({
    required String userId,
    required DateTime date,
  }) async {
    final formatted = "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    final url =
        Uri.parse("$_baseUrl/reminder/day?user_id=$userId&date=$formatted");

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Fetch failed: ${res.statusCode}");
    }

    final List data = json.decode(res.body);
    print("Fetched events: $data");
    return data.map((e) => Event.fromJson(e)).toList();
  }

  static Future<void> deleteReminder(
      {required String userId, required String reminderId}) async {
    try {
      // LƯU Ý: Bạn cần kiểm tra lại API backend của bạn.
      // Ở đây giả sử endpoint là '/reminder/delete' và phương thức là DELETE
      final Uri url = Uri.parse('$_baseUrl/reminder/delete/$reminderId');

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'id': reminderId, // Hoặc 'reminder_id' tùy vào backend của bạn
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Reminder deleted successfully");
      } else {
        throw Exception('Failed to delete reminder: ${response.statusCode}');
      }
    } catch (e) {
      print("Error deleting reminder: $e");
      throw Exception('Error connecting to server');
    }
  }
}
