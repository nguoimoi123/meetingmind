import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MindmapService {
  static Future<Map<String, dynamic>> generateMindmap(
    String folderId,
    String userId, {
    String? name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/grap_visual/generate_visual/$folderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name ?? 'Sơ đồ tư duy',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate mindmap: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating mindmap: $e');
    }
  }

  static Future<Map<String, dynamic>> getMindmap(String resultId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/grap_visual/get_visual/$resultId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get mindmap: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting mindmap: $e');
    }
  }
}
