import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_auth_headers.dart';

class NotebookListService {
  static Future<List<dynamic>> fetchFolders(String userId) async {
    final baseUrl = apiBaseUrl;

    final response = await http.get(
      Uri.parse('$baseUrl/folder/$userId'),
      headers: await ApiAuthHeaders.build(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load folders: ${response.statusCode}');
    }
  }

  static Future<void> deleteFolder(String folderId) async {
    final baseUrl = apiBaseUrl;

    final response = await http.delete(
      Uri.parse('$baseUrl/folder/delete/$folderId'),
      headers: await ApiAuthHeaders.build(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete folder: ${response.statusCode}');
    }
  }
}
