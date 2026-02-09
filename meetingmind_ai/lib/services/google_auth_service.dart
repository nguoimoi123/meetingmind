import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GoogleAuthService {
  // 🔴 PHẢI TRÙNG GOOGLE_CLIENT_ID BACKEND
  static const String _webClientId =
      "828381156455-k2cht1g24gd4mv8nva7d19r5gh4hje85.apps.googleusercontent.com";

  // Sử dụng getter để lấy URL động theo platform
  static String get _backendUrl => googleAuthEndpoint;
  // Android emulator → 10.0.2.2:5001
  // iOS simulator → localhost:5001

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  /// Step 1: Login Google → lấy ID TOKEN
  Future<String?> loginWithGoogle() async {
    try {
      print("🔵 Starting Google Sign-In...");
      print("🔵 Web Client ID: $_webClientId");
      
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        print("❌ Google Sign-In returned null");
        print("❌ Possible reasons:");
        print("   1. User cancelled the sign-in");
        print("   2. Keychain access denied (missing entitlements)");
        print("   3. Bundle ID not authorized in Google Cloud Console");
        print("   4. Info.plist GIDClientID incorrect");
        return null;
      }

      final auth = await account.authentication;
      
      // Print token để debug
      print("\n" + "="*70);
      print("✅ Google Sign-In Success!");
      print("📧 Email: ${account.email}");
      print("👤 Name: ${account.displayName}");
      print("🔑 ID Token (first 50 chars): ${auth.idToken?.substring(0, 50)}...");
      print("="*70 + "\n");
      
      return auth.idToken; // 🔥 QUAN TRỌNG
    } catch (e, stackTrace) {
      print("❌ Google login error: $e");
      print("❌ Stack trace: $stackTrace");
      return null;
    }
  }

  /// Step 2: Gửi ID TOKEN lên backend
  Future<Map<String, dynamic>?> sendTokenToBackend(String idToken) async {
    try {
      print("🔵 Sending token to: $_backendUrl");
      
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_token": idToken}),
      );

      print("🔵 Backend response status: ${response.statusCode}");
      print("🔵 Backend response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Backend login successful!");
        return data as Map<String, dynamic>;
      }
      
      print("❌ Backend returned non-200 status: ${response.statusCode}");
      return null;
    } catch (e) {
      print("❌ Backend connection error: $e");
      return null;
    }
  }
}
