import 'dart:convert';
import 'package:http/http.dart' as http;

class NotebookService {
  static const String _baseUrl = 'http://192.168.90.100:5000';
  static Future<void> createNotebook({
    required String userId,
    required String name,
    required String description,
  }) async {
    const String apiUrl = '$_baseUrl/folder/add';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "user_id": userId,
        "name": name,
        "description": description,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}
