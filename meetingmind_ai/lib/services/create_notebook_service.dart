import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_auth_headers.dart';

class NotebookService {
  static Future<void> createNotebook({
    required String userId,
    required String name,
    required String description,
  }) async {
    final apiUrl = '$apiBaseUrl/folder/add';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: await ApiAuthHeaders.build(
        json: true,
        extra: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
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
