import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  GoogleSignInAccount? _googleUser;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  GoogleSignInAccount? get googleUser => _googleUser;
  String? get userId => _userId;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  void loginWithGoogle({
    required GoogleSignInAccount? user,
    required String userIdFromBackend,
  }) {
    _googleUser = user;
    _userId = userIdFromBackend;
    _isLoggedIn = true;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    _googleUser = null;
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
