import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static final String? BASE_URL = dotenv.env['API_BASE_URL'];

  static Future<String> ask({
    required String userId,
    required String folderId,
    required String question,
  }) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/chat/notebook'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'folder_id': folderId,
        'question': question,
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
