import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _baseUrl = 'http://192.168.230.243:5000';
  final String _currentUserId = "user_123"; // User giả định

  Future<String> askAboutMeeting(String sid, String question) async {
    final uri = Uri.parse('$_baseUrl/chat/meeting');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {"sid": sid, "user_id": _currentUserId, "query": question}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? "Không có phản hồi.";
      } else {
        return "Lỗi kết nối server.";
      }
    } catch (e) {
      return "Lỗi: $e";
    }
  }
}
