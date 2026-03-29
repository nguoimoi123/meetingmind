import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meeting_summary.dart';
import '../config/api_config.dart';
import 'api_auth_headers.dart';

class SummaryService {
  static String get _baseUrl => apiBaseUrl;

  static Future<MeetingSummary> summarize(
    String sid, {
    required String userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/summarize/$sid?user_id=$userId');

    final response = await http
        .get(
          uri,
          headers: await ApiAuthHeaders.build(),
        )
        .timeout(const Duration(seconds: 30));

    print("📦 RAW API RESPONSE = ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
          'Summarize failed: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body);
    return MeetingSummary.fromJson(json);
  }
}
