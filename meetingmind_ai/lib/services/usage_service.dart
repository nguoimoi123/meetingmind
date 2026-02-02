import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UsageService {
  static Future<Map<String, dynamic>> getUsage({
    required String userId,
  }) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/user/usage/$userId'));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode == 200) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Failed to load usage';
    throw Exception(message);
  }
}
