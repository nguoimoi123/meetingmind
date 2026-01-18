import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meeting_summary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SummaryService {
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

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
