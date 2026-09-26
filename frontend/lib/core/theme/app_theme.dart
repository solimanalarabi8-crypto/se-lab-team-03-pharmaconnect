import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmaTheme {
  // الألوان الطبية المعتمدة للوضع النهاري (Light Palette)
  static const Color primaryGreen = Color(0xFF059669);       // الأخضر الزمردي الرئيسي
  static const Color primaryGreenLight = Color(0xFF10B981);  // الأخضر الحيوي
  static const Color primaryGreenDark = Color(0xFF065F46);   // الأخضر الداكن
  static const Color mintBackground = Color(0xFFECFDF5);    // خلفية ناعمة
  static const Color mintAccent = Color(0xFFD1FAE5);        // شارات التوفر
  static const Color surfaceWhite = Color(0xFFFFFFFF);      // أسطح البطاقات
  static const Color backgroundLight = Color(0xFFF8FAFC);   // خلفية التطبيق النهارية
  static const Color textMain = Color(0xFF0F172A);          // نصوص رئيسية
  static const Color textMuted = Color(0xFF64748B);         // نصوص ثانوية

  // الألوان الطبية المعتمدة للوضع الليلي الفاخر (Medical Dark Palette)
  static const Color darkBackground = Color(0xFF0B1120);    // خلفية ليلية عميقة
  static const Color darkSurface = Color(0xFF1E293B);       // سطح البطاقات الليلي
  static const Color darkSurfaceVariant = Color(0xFF334155);// سطح ثانوي
  static const Color darkSurfaceElevated = Color(0xFF334155);// سطح مرتفع
  static const Color darkBorder = Color(0xFF334155);        // حدود العناصر الليلية
  static const Color darkTextMain = Color(0xFFF8FAFC);      // نصوص ليلية ناصعة
  static const Color darkTextMuted = Color(0xFF94A3B8);     // نصوص ليلية ثانوية
  static const Color darkNeonGreen = Color(0xFF34D399);     // إضاءة خضراء ليلية

  // شارات الحالات
  static const Color statusWarning = Color(0xFFD97706);     // وشيك النفاذ
  static const Color statusDanger = Color(0xFFDC2626);      // غير متوفر أو ملغي
  static const Color statusSuccess = Color(0xFF15803D);     // متوفر أو مكتمل

  /// الثيم النهاري المشرق (Light Theme)
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.tajawalTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryGreenLight,
        surface: surfaceWhite,
        error: statusDanger,
        onPrimary: Colors.white,
        onSurface: textMain,
        onSurfaceVariant: textMuted,
      ),
      listTileTheme: ListTileThemeData(
        textColor: textMain,
        iconColor: primaryGreenDark,
        titleTextStyle: GoogleFonts.tajawal(
          color: textMain,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: GoogleFonts.tajawal(
          color: textMuted,
          fontSize: 11,
        ),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: primaryGreenDark),
        titleTextStyle: GoogleFonts.tajawal(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: GoogleFonts.tajawal(color: textMuted, fontSize: 13),
        labelStyle: GoogleFonts.tajawal(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textMuted,
        elevation: 8,
      ),
    );
  }

  /// الثيم الليلي الطبي الفاخر (Medical Dark Theme)
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.tajawalTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreenLight,
      scaffoldBackgroundColor: darkBackground,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreenLight,
        secondary: darkNeonGreen,
        surface: darkSurface,
        error: statusDanger,
        onPrimary: darkBackground,
        onSurface: darkTextMain,
        onSurfaceVariant: darkTextMuted,
      ),
      listTileTheme: ListTileThemeData(
        textColor: darkTextMain,
        iconColor: darkNeonGreen,
        titleTextStyle: GoogleFonts.tajawal(
          color: darkTextMain,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: GoogleFonts.tajawal(
          color: darkTextMuted,
          fontSize: 11,
        ),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: darkTextMain,
        displayColor: darkTextMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: darkNeonGreen),
        titleTextStyle: GoogleFonts.tajawal(
          color: darkTextMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenLight,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF151E2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: GoogleFonts.tajawal(color: darkTextMuted, fontSize: 13),
        labelStyle: GoogleFonts.tajawal(color: darkTextMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkNeonGreen, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkNeonGreen,
        unselectedItemColor: darkTextMuted,
        elevation: 8,
      ),
    );
  }
}
