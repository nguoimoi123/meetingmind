import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ReportService {
  static Future<String> exportMarkdown({
    required String title,
    required String summary,
    required List<String> actionItems,
    required List<String> keyDecisions,
    required String fullTranscript,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/report/markdown'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'summary': summary,
        'action_items': actionItems,
        'key_decisions': keyDecisions,
        'full_transcript': fullTranscript,
      }),
    );

    if (res.statusCode == 200) {
      return res.body;
    }

    throw Exception('Export markdown failed');
  }

  static Future<List<int>> exportPdf({
    required String title,
    required String summary,
    required List<String> actionItems,
    required List<String> keyDecisions,
    required String fullTranscript,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/report/pdf'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'summary': summary,
        'action_items': actionItems,
        'key_decisions': keyDecisions,
        'full_transcript': fullTranscript,
      }),
    );

    if (res.statusCode == 200) {
      return res.bodyBytes;
    }

    throw Exception('Export PDF failed');
  }
}
