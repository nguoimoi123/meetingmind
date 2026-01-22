import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  // ignore: constant_identifier_names
  static final String? BASE_URL = dotenv.env['API_BASE_URL'];

  /// Lấy thông tin user
  static Future<Map<String, dynamic>> getUserInfo(String userId) async {
    final res = await http.get(Uri.parse('$BASE_URL/user/$userId'));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to load user info');
    }
  }
}
