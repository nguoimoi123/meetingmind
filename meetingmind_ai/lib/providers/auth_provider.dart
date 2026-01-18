import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import mới

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  GoogleSignInAccount? _googleUser;
  String? _userId;

  // SharedPreferences instance
  SharedPreferences? _prefs;

  bool get isLoggedIn => _isLoggedIn;
  GoogleSignInAccount? get googleUser => _googleUser;
  String? get userId => _userId;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // --- HÀM KHỞI TẠO: GỌI KHI APP CHẠY (main.dart hoặc SplashScreen) ---
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Đọc dữ liệu đã lưu
    _isLoggedIn = _prefs!.getBool('isLoggedIn') ?? false;
    _userId = _prefs!.getString('userId');
    _googleUser = _googleSignIn.currentUser; // Thử lấy session google hiện có

    notifyListeners();
  }

  // --- HÀM ĐĂNG NHẬP GOOGLE ---
  void loginWithGoogle({
    required GoogleSignInAccount? user,
    required String userIdFromBackend,
  }) async {
    _googleUser = user;
    _userId = userIdFromBackend;
    _isLoggedIn = true;

    await _saveData(); // Lưu xuống bộ nhớ
    notifyListeners();
  }

  // --- HÀM ĐĂNG NHẬP THỦ CÔNG (Dummy) ---
  void login() async {
    // Giả lập user_id cho local login
    _userId = "6965304ba729391015e6d079";
    _isLoggedIn = true;

    await _saveData(); // Lưu xuống bộ nhớ
    notifyListeners();
  }

  // --- HÀM ĐĂNG XUẤT ---
  Future<void> logout() async {
    await _googleSignIn.signOut();
    _googleUser = null;
    _userId = null;
    _isLoggedIn = false;

    await _clearData(); // Xóa dữ liệu lưu trữ
    notifyListeners();
  }

  // --- HÀM HỖ TRỢ LƯU TRỮ ---
  Future<void> _saveData() async {
    if (_prefs != null) {
      await _prefs!.setBool('isLoggedIn', _isLoggedIn);
      await _prefs!.setString('userId', _userId ?? "");
      // Bạn có thể lưu thêm tên, email nếu cần
    }
  }

  Future<void> _clearData() async {
    if (_prefs != null) {
      await _prefs!.clear(); // Hoặc set các key về false/null
    }
  }
}
