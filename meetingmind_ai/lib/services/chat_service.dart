import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ChatService {
  static Future<String> ask({
    required String userId,
    required String folderId,
    required String question,
    List<String>? fileIds,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/chat/notebook'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'folder_id': folderId,
        'question': question,
        if (fileIds != null && fileIds.isNotEmpty) 'file_ids': fileIds,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['answer'] ?? 'No answer';
    } else {
      throw Exception('Chat failed');
    }
  }
}
