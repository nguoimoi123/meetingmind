import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SearchService {
  static Future<Map<String, dynamic>> searchAll({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    final uri =
        Uri.parse('$apiBaseUrl/search?user_id=$userId&q=$query&limit=$limit');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Search failed');
  }
}
