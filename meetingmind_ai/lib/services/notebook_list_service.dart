import 'dart:convert';
import 'package:http/http.dart' as http;

class NotebookListService {
  static const String _baseUrl = 'http://192.168.90.100:5000';
  static Future<List<dynamic>> fetchFolders(String userId) async {
    const baseUrl = _baseUrl;

    final response = await http.get(
      Uri.parse('$baseUrl/folder/$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load folders: ${response.statusCode}');
    }
  }

  static Future<void> deleteFolder(String folderId) async {
    final baseUrl = _baseUrl;

    final response = await http.delete(
      Uri.parse('$baseUrl/folder/delete/$folderId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete folder: ${response.statusCode}');
    }
  }
}
