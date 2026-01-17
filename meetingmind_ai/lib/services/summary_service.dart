import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meeting_summary.dart';

class SummaryService {
  static const String _baseUrl = 'http://192.168.115.243:5000';

  static Future<MeetingSummary> summarize(String sid) async {
    final uri = Uri.parse('$_baseUrl/summarize/$sid');

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    print("📦 RAW API RESPONSE = ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
          'Summarize failed: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body);
    return MeetingSummary.fromJson(json);
  }
}
