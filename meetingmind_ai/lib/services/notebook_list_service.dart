import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotebookListService {
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];
  static Future<List<dynamic>> fetchFolders(String userId) async {
    final baseUrl = _baseUrl;

    final response = await http.get(
      Uri.parse('$baseUrl/folder/$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load folders: ${response.statusCode}');
    }
  }
}
