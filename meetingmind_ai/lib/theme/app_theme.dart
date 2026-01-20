import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // =================================================================
  // 1. CÁC MÀU SẮC NGUỒN (SOURCE OF TRUTH)
  // Phong cách Monochrome (Đen - Trắng - Xám) kết hợp Icon Sống động
  // =================================================================

  // Màu chính: ĐEN TUYỐT ĐỐI -> Dùng cho các nút bấm chính, FAB
  static const Color primaryColor = Color(0xFF000000);

  // Màu phụ: Xám Đậm -> Dùng cho các icon hoặc trạng thái active
  static const Color accentColor = Color(0xFF121212);

  // Màu thứ cấp: Xám Nhạt -> Dùng cho văn bản mô tả (Body text)
  static const Color secondaryColor = Color(0xFF757575);

  // Nền ứng dụng: TRẮNG TINH
  static const Color backgroundColor = Color(0xFFFFFFFF);

  // Màu bề mặt: TRẮNG
  static const Color surfaceColor = Color(0xFFFFFFFF);

  static const Color errorColor =
      Color(0xFFD32F2F); // Giữ màu đỏ chuẩn Material
  static const Color successColor = Color(0xFF2E7D32);
  static const Color brightBluer =
      Color(0xFF000000); // Đổi sang đen cho đồng bộ

  // -----------------------------------------------------------------
  // MỚI: MÀU SẮC ICON SỐNG ĐỘNG (VIBRANT ICON COLOR)
  // Dùng để tạo điểm nhấn đa dạng cho các icon, thay vì chỉ đen trắng
  // -----------------------------------------------------------------
  static const Color vibrantIconColor =
      Color(0xFF2962FF); // Xanh Azure đậm rực rỡ

  // Dark Mode Colors (Đảo ngược: Nền đen, chữ trắng)
  static const Color darkBackgroundColor = Color(0xFF000000);
  static const Color darkSurfaceColor = Color(0xFF121212);
  static const Color darkOnSurfaceColor = Color(0xFFFFFFFF);

  // =================================================================
  // 2. LIGHT THEME
  // =================================================================
  static ThemeData get light {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: primaryColor, // Đen
      secondary: accentColor, // Xám đậm
      surface: surfaceColor, // Trắng
      background: backgroundColor, // Trắng
      error: errorColor,
      onPrimary: Colors.white, // Chữ trên nút Đen là Trắng
      onSecondary: Colors.white,
      onSurface: Color(0xFF000000), // Chữ chính là Đen
      onBackground: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // -----------------------------------------------------------------
      // CẤU HÌNH ICON SỐNG ĐỘNG
      // -----------------------------------------------------------------
      iconTheme: const IconThemeData(
        color: vibrantIconColor, // Icon mặc định sẽ có màu xanh rực rỡ
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: vibrantIconColor,
      ),

      // Font chữ
      textTheme: GoogleFonts.interTextTheme().copyWith(
        // Tiêu đề màu ĐEN
        headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF000000)),
        headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000)),

        // Nội dung chính màu ĐEN
        bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF000000)),

        // Nội dung phụ màu XÂM
        bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400, color: secondaryColor),

        // Label (Nút bấm) chữ Trắng
        labelLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),

      // AppBar: Nền trắng, chữ đen
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Color(0xFF000000),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
            color: Color(
                0xFF000000)), // Icon AppBar giữ màu đen để nhấn mạnh sự tối giản
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000)),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card: Để tạo hiệu ứng "Giấy trên nền trắng", ta dùng màu xám rất nhạt cho nền thẻ
      // hoặc dùng màu Trắng với viền xám.
      // Ở đây tôi dùng màu Trắng với viền xám nhạt (Border)
      cardTheme: CardThemeData(
        color: surfaceColor, // Nền thẻ trắng
        elevation: 0, // Bỏ bóng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
              color: Color(0xFFE0E0E0), width: 1), // Viền xám tinh tế
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),

      // Elevated Button: NỀN ĐEN, CHỮ TRẮNG
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Nền đen
          foregroundColor: Colors.white, // Chữ trắng
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(30)), // Bo tròn nhiều (Capsule style)
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Outlined Button: Viền ĐEN, Chữ ĐEN
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF000000),
          side: const BorderSide(color: Color(0xFF000000), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),

      // TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF5F5F5), // Nền ô input màu xám nhạt
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Bỏ viền mặc định
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF000000), width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: secondaryColor),
        // Icon trong TextField cũng mang màu sống động
        prefixIconColor: vibrantIconColor,
        suffixIconColor: vibrantIconColor,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor:
            vibrantIconColor, // Chuyển sang màu sống động khi được chọn
        unselectedItemColor: Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
      ),

      // Floating Action Button: NỀN ĐEN
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  // =================================================================
  // 3. DARK THEME
  // =================================================================
  static ThemeData get dark {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: Colors.white, // Dark mode: Nút màu trắng
      secondary: Color(0xFFE0E0E0),
      surface: darkSurfaceColor,
      background: darkBackgroundColor,
      error: errorColor,
      onPrimary: Colors.black, // Chữ trên nút trắng là đen
      onSecondary: Colors.black,
      onSurface: darkOnSurfaceColor,
      onBackground: darkOnSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,

      // -----------------------------------------------------------------
      // CẤU HÌNH ICON SỐNG ĐỘNG (DARK MODE)
      // -----------------------------------------------------------------
      iconTheme: const IconThemeData(
        color: vibrantIconColor, // Giữ màu xanh rực rỡ trong Dark Mode
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: vibrantIconColor,
      ),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: darkOnSurfaceColor),
        headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: darkOnSurfaceColor),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkOnSurfaceColor),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: darkOnSurfaceColor.withOpacity(0.7)),
        labelLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkOnSurfaceColor,
        elevation: 0,
        centerTitle: true,
        // Icon AppBar trong dark mode giữ màu trắng
        iconTheme: const IconThemeData(color: darkOnSurfaceColor),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkOnSurfaceColor),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: darkOnSurfaceColor.withOpacity(0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Nút trắng trong Dark mode
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2C2C2C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        hintStyle:
            GoogleFonts.inter(color: darkOnSurfaceColor.withOpacity(0.5)),
        // Icon trong TextField (Dark Mode)
        prefixIconColor: vibrantIconColor,
        suffixIconColor: vibrantIconColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor:
            vibrantIconColor, // Chuyển sang màu sống động khi được chọn
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}
