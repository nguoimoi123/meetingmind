import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import mới
import 'package:meetingmind_ai/services/plan_service.dart';
import 'package:meetingmind_ai/services/team_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  GoogleSignInAccount? _googleUser;
  String? _userId;
  String? _email;
  String? _name;
  String _plan = 'free';
  Map<String, dynamic> _limits = {};

  // SharedPreferences instance
  SharedPreferences? _prefs;

  bool get isLoggedIn => _isLoggedIn;
  GoogleSignInAccount? get googleUser => _googleUser;
  String? get userId => _userId;
  String? get email => _email;
  String? get name => _name;
  String get plan => _plan;
  Map<String, dynamic> get limits => _limits;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // --- HÀM KHỞI TẠO: GỌI KHI APP CHẠY (main.dart hoặc SplashScreen) ---
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Đọc dữ liệu đã lưu
    _isLoggedIn = _prefs!.getBool('isLoggedIn') ?? false;
    _userId = _prefs!.getString('userId');
    _email = _prefs!.getString('email');
    _name = _prefs!.getString('name');
    _plan = _prefs!.getString('plan') ?? 'free';
    final limitsRaw = _prefs!.getString('plan_limits');
    if (limitsRaw != null && limitsRaw.isNotEmpty) {
      try {
        _limits = jsonDecode(limitsRaw) as Map<String, dynamic>;
      } catch (_) {
        _limits = {};
      }
    }
    _googleUser = _googleSignIn.currentUser; // Thử lấy session google hiện có

    if (_isLoggedIn && _userId != null && _userId!.isNotEmpty) {
      TeamNotificationService().connect(_userId!);
      await refreshPlanInfo();
    }

    notifyListeners();
  }

  // --- HÀM ĐĂNG NHẬP GOOGLE ---
  Future<void> loginWithGoogle({
    required GoogleSignInAccount? user,
    required String userIdFromBackend,
    String? plan,
  }) async {
    _googleUser = user;
    _userId = userIdFromBackend;
    _email = user?.email;
    _name = user?.displayName;
    _plan = plan ?? _plan;
    _isLoggedIn = true;

    await _saveData(); // Lưu xuống bộ nhớ
    if (_userId != null && _userId!.isNotEmpty) {
      TeamNotificationService().connect(_userId!);
    }
    await refreshPlanInfo();
    notifyListeners();
  }

  // --- HÀM ĐĂNG NHẬP THỦ CÔNG (Dummy) ---
  void login() async {
    // Giả lập user_id cho local login
    _userId = "local_dummy_user_id";
    _isLoggedIn = true;

    await _saveData(); // Lưu xuống bộ nhớ
    if (_userId != null && _userId!.isNotEmpty) {
      TeamNotificationService().connect(_userId!);
    }
    notifyListeners();
  }

  // --- HÀM ĐĂNG NHẬP BẰNG EMAIL/PASSWORD ---
  Future<void> loginWithCredentials({
    required String userId,
    String? email,
    String? name,
    String? plan,
  }) async {
    _googleUser = null;
    _userId = userId;
    _email = email;
    _name = name;
    _plan = plan ?? _plan;
    _isLoggedIn = true;

    await _saveData();
    if (_userId != null && _userId!.isNotEmpty) {
      TeamNotificationService().connect(_userId!);
    }
    await refreshPlanInfo();
    notifyListeners();
  }

  // --- HÀM ĐĂNG XUẤT ---
  Future<void> logout() async {
    await _googleSignIn.signOut();
    TeamNotificationService().disconnect();
    _googleUser = null;
    _userId = null;
    _email = null;
    _name = null;
    _plan = 'free';
    _limits = {};
    _isLoggedIn = false;

    await _clearData(); // Xóa dữ liệu lưu trữ
    notifyListeners();
  }

  // --- HÀM HỖ TRỢ LƯU TRỮ ---
  Future<void> _saveData() async {
    if (_prefs != null) {
      await _prefs!.setBool('isLoggedIn', _isLoggedIn);
      await _prefs!.setString('userId', _userId ?? "");
      await _prefs!.setString('email', _email ?? "");
      await _prefs!.setString('name', _name ?? "");
      await _prefs!.setString('plan', _plan);
      await _prefs!.setString('plan_limits', jsonEncode(_limits));
      // Bạn có thể lưu thêm tên, email nếu cần
    }
  }

  Future<void> setPlan(String plan) async {
    _plan = plan;
    await _saveData();
    await refreshPlanInfo();
    notifyListeners();
  }

  Future<void> refreshPlanInfo() async {
    if (_userId == null || _userId!.isEmpty) return;
    try {
      final data = await PlanService.getPlanInfo(userId: _userId!);
      final newPlan = data['plan']?.toString();
      final newLimits = data['limits'] as Map<String, dynamic>?;
      if (newPlan != null && newPlan.isNotEmpty) {
        _plan = newPlan;
      }
      if (newLimits != null) {
        _limits = newLimits;
      }
      await _saveData();
    } catch (_) {}
  }

  Future<void> _clearData() async {
    if (_prefs != null) {
      await _prefs!.clear(); // Hoặc set các key về false/null
    }
  }
}
