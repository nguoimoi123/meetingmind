import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileService {
  // ignore: constant_identifier_names
  static final String? BASE_URL = dotenv.env['API_BASE_URL'];

  /// Lấy folder + danh sách file
  static Future<Map<String, dynamic>> getFolder(String folderId) async {
    final res = await http.get(Uri.parse('$BASE_URL/file/folder/$folderId'));
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
      Uri.parse('$BASE_URL/file/upload'),
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
}
