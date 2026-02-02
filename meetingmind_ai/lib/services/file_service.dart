import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../config/api_config.dart';

class FileService {
  /// Lấy folder + danh sách file
  static Future<Map<String, dynamic>> getFolder(String folderId) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/file/folder/$folderId'));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to load folder');
    }
  }

  /// Upload file
  static Future<void> uploadFile({
    required String userId,
    required String folderId,
    required PlatformFile file,
    required String content,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/file/upload'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'folder_id': folderId,
        'filename': file.name,
        'file_type': file.extension ?? '',
        'size': file.size,
        'content': content,
      }),
    );

    print("UPLOAD STATUS: ${res.statusCode}");
    print("UPLOAD BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Upload failed');
    }
  }

  static Future<void> deleteFile(String fileId) async {
    final res = await http.delete(Uri.parse('$apiBaseUrl/file/delete/$fileId'));
    if (res.statusCode != 200) {
      throw Exception('Delete failed');
    }
  }

  static Future<Uint8List> downloadFile(String fileId) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/file/download/$fileId'));
    if (res.statusCode != 200) {
      throw Exception('Download failed');
    }
    return res.bodyBytes;
  }
}
