import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String BASE_URL = 'http://192.168.178.243:5000';

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
