import 'package:flutter/material.dart';
import 'package:meetingmind_ai/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Khởi tạo với theme sáng là mặc định
  ThemeData _themeData = AppTheme.light;
  bool _isDarkMode = false;

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Hàm để chuyển đổi theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeData = _isDarkMode ? AppTheme.dark : AppTheme.light;
    _saveThemeToPrefs();
    notifyListeners(); // Thông báo cho các widget lắng nghe rằng theme đã thay đổi
  }

  // Lưu trạng thái theme vào bộ nhớ
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Tải trạng thái theme từ bộ nhớ khi khởi động
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeData = _isDarkMode ? AppTheme.dark : AppTheme.light;
    notifyListeners();
  }
}
