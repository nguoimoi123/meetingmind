import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ReportExportService {
  static const String _baseUrl = apiBaseUrl;

  static Future<Uint8List> generateDocxBytes({
    required String title,
    required String summary,
    required List<String> actionItems,
    required List<String> keyDecisions,
    required String fullTranscript,
  }) async {
    final uri = Uri.parse('$_baseUrl/report/docx');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'summary': summary,
            'action_items': actionItems,
            'key_decisions': keyDecisions,
            'full_transcript': fullTranscript,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Export failed: ${response.statusCode}');
    }

    return response.bodyBytes;
  }

  static Future<void> uploadReportToNotebook({
    required String userId,
    required String folderId,
    required String filename,
    required String content,
  }) async {
    final uri = Uri.parse('$_baseUrl/file/upload');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'folder_id': folderId,
            'filename': filename,
            'file_type': 'docx',
            'size': content.length,
            'content': content,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }
}
