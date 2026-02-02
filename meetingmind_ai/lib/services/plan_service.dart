import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PlanService {
  static Future<Map<String, dynamic>> getPlanInfo({
    required String userId,
  }) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/user/plan/$userId'));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode == 200) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Failed to load plan info';
    throw Exception(message);
  }
}
