import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SubscriptionService {
  static Future<List<String>> createUpgradeCodes({
    required String plan,
    int count = 1,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/user/upgrade-code/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'plan': plan,
        'count': count,
      }),
    );

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode == 201) {
      final codes = (body['codes'] as List).cast<String>();
      return codes;
    }

    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Create code failed';
    throw Exception(message);
  }

  static Future<String> redeemCode({
    required String userId,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/user/upgrade'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'code': code,
      }),
    );

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode == 200) {
      return body['plan']?.toString() ?? 'free';
    }

    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Upgrade failed';
    throw Exception(message);
  }
}
