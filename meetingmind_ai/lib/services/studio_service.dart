import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_auth_headers.dart';

class StudioService {
  /// Gọi API generate audio từ folder
  static Future<Map<String, dynamic>> generateAudio(String folderId, String userId) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/tts_studio/generate_audio/$folderId'),
      headers: await ApiAuthHeaders.build(json: true),
      body: jsonEncode({'user_id': userId}),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else if (res.statusCode == 404) {
      throw NoContentException('No content found in the specified folder.');
    } else {
      final errorBody = json.decode(res.body);
      throw Exception(errorBody['error'] ?? 'Failed to generate audio');
    }
  }

  /// Lấy danh sách studio results theo folder
  static Future<List<Map<String, dynamic>>> getResultsByFolder(String folderId) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/studio_result/folder/$folderId'),
      headers: await ApiAuthHeaders.build(),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } else {
      throw Exception('Failed to load studio results');
    }
  }

  /// Xóa studio result
  static Future<void> deleteResult(String resultId) async {
    final res = await http.delete(
      Uri.parse('$apiBaseUrl/studio_result/delete/$resultId'),
      headers: await ApiAuthHeaders.build(),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete result');
    }
  }
}

class NoContentException implements Exception {
  final String message;
  NoContentException(this.message);
  
  @override
  String toString() => message;
}
