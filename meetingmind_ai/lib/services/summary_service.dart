import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meeting_summary.dart';
import '../config/api_config.dart';

class SummaryService {
  static const String _baseUrl = apiBaseUrl;

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
