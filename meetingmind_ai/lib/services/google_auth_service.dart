import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
  // 🔴 PHẢI TRÙNG GOOGLE_CLIENT_ID BACKEND
  static const String _webClientId =
      "828381156455-k2cht1g24gd4mv8nva7d19r5gh4hje85.apps.googleusercontent.com";

  static final String _backendUrl =
      dotenv.env['API_BASE_URL']! + "/auth/google";
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
  Future<String?> sendTokenToBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_token": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id']; // backend phải trả field này
      }
      return null;
    } catch (e) {
      print("Backend connection error: $e");
      return null;
    }
  }
}
