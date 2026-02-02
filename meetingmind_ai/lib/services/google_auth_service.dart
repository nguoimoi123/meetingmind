import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GoogleAuthService {
  // 🔴 PHẢI TRÙNG GOOGLE_CLIENT_ID BACKEND
  static const String _webClientId =
      "828381156455-k2cht1g24gd4mv8nva7d19r5gh4hje85.apps.googleusercontent.com";

  static const String _backendUrl = googleAuthEndpoint;
  // Android emulator → 10.0.2.2
  // iOS simulator → http://localhost:5000

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  /// Step 1: Login Google → lấy ID TOKEN
  Future<String?> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.idToken; // 🔥 QUAN TRỌNG
    } catch (e) {
      print("Google login error: $e");
      return null;
    }
  }

  /// Step 2: Gửi ID TOKEN lên backend
  Future<Map<String, dynamic>?> sendTokenToBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_token": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Backend connection error: $e");
      return null;
    }
  }
}
