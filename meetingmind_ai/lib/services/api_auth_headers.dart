import 'package:shared_preferences/shared_preferences.dart';

class ApiAuthHeaders {
  static Future<Map<String, String>> build({
    bool json = false,
    Map<String, String>? extra,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }
}
