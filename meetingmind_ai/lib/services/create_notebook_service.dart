import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotebookService {
  static Future<void> createNotebook({
    required String userId,
    required String name,
    required String description,
  }) async {
    const String apiUrl = '$apiBaseUrl/folder/add';

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
