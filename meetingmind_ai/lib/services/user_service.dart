import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_auth_headers.dart';

class UserService {
  static Future<Map<String, dynamic>> getUserInfo(String userId) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/user/$userId'),
      headers: await ApiAuthHeaders.build(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load user info');
  }
}
