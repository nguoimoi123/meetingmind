import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // =================================================================
  // 1. CÁC MÀU SẮC NGUỒN (SOURCE OF TRUTH)
  // Đây là nơi duy nhất định nghĩa màu sắc. Mọi thay đổi sẽ được áp dụng toàn bộ.
  // =================================================================
  static const Color primaryColor = Color(0xFF0A2A5E); // Deep Blue
  static const Color accentColor = Color(0xFF007BFF); // Bright Blue
  static const Color secondaryColor = Color(0xFF4A5568); // Slate Gray
  static const Color backgroundColor = Color(0xFFF7FAFC); // Light Gray
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color errorColor = Color(0xFFE53E3E); // Red
  static const Color successColor = Color(0xFF48BB78); // Green
  static const Color brightBluer = Color(0xFFFFA500); // Orange

  // Dark Mode Colors
  static const Color darkBackgroundColor = Color(0xFF111721);
  static const Color darkSurfaceColor = Color(0xFF1A202C);
  static const Color darkOnSurfaceColor = Color(0xFFE2E8F0);

  // =================================================================
  // 2. LIGHT THEME
  // =================================================================
  static ThemeData get light {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white, // Chữ trên nền primary
      onSecondary: Colors.white, // Chữ trên nền secondary
      onSurface: primaryColor, // Chữ trên nền surface
      onBackground: primaryColor, // Chữ trên nền background
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // Font chữ toàn bộ ứng dụng
      textTheme: GoogleFonts.interTextTheme().copyWith(
        // Định nghĩa các style văn bản để dùng nhất quán
        headlineLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
        headlineMedium: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.normal, color: primaryColor),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.normal, color: secondaryColor),
        labelLarge: GoogleFonts.inter(
            // Dùng cho button
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      ),

      // Giao diện thanh AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Icon status bar tối
      ),

      // Giao diện các thẻ (Card)
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Giao diện các nút bấm (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),

      // Giao diện các nút bấm (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Giao diện các ô nhập liệu (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: secondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
      ),

      // Giao diện thanh điều hướng dưới cùng
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryColor,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal),
      ),
    );
  }

  // =================================================================
  // 3. DARK THEME
  // =================================================================
  static ThemeData get dark {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: darkSurfaceColor,
      background: darkBackgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkOnSurfaceColor,
      onBackground: darkOnSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkOnSurfaceColor),
        headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkOnSurfaceColor),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: darkOnSurfaceColor),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: darkOnSurfaceColor.withOpacity(0.8)),
        labelLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkOnSurfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkOnSurfaceColor),
        systemOverlayStyle: SystemUiOverlayStyle.light, // Icon status bar sáng
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: darkOnSurfaceColor.withOpacity(0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkOnSurfaceColor,
          side: BorderSide(color: darkOnSurfaceColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkOnSurfaceColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkOnSurfaceColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        hintStyle:
            GoogleFonts.inter(color: darkOnSurfaceColor.withOpacity(0.5)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: darkOnSurfaceColor.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal),
      ),
    );
  }
}
