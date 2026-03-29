import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_auth_headers.dart';

class SearchService {
  static Future<Map<String, dynamic>> searchAll({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    final uri =
        Uri.parse('$apiBaseUrl/search?user_id=$userId&q=$query&limit=$limit');
    final res = await http.get(
      uri,
      headers: await ApiAuthHeaders.build(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Search failed');
  }
}
