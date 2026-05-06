import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_auth_headers.dart';

class ChatService {
  final String userId;

  ChatService({required this.userId});

  String _sanitizeAiAnswer(String text) {
    return text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*/{2,}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<String> askAboutMeeting(String sid, String question) async {
    final uri = Uri.parse('$apiBaseUrl/chat/meeting');

    try {
      final response = await http
          .post(
            uri,
            headers: await ApiAuthHeaders.build(json: true),
            body: jsonEncode({
              "sid": sid,
              "user_id": userId,
              "query": question,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer']?.toString() ?? 'Khong co phan hoi.';
        return _sanitizeAiAnswer(answer);
      }
      return 'Loi ket noi server.';
    } catch (e) {
      return 'Loi: $e';
    }
  }
}
