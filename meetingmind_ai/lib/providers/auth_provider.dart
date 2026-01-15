import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  GoogleSignInAccount? _googleUser;

  bool get isLoggedIn => _isLoggedIn;
  GoogleSignInAccount? get googleUser => _googleUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void loginWithGoogle(GoogleSignInAccount user) {
    _googleUser = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    // 1️⃣ Logout Google
    await _googleSignIn.signOut();

    // 2️⃣ Reset state
    _googleUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
