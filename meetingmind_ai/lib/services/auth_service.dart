import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode == 200) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Login failed';
    throw Exception(message);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/user/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode == 200 || res.statusCode == 201) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Register failed';
    throw Exception(message);
  }
}
