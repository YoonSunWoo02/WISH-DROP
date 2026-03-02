import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 위시드롭 웹 디자인 팔레트 (HTML 랜딩과 동일)
  static const Color primary = Color(0xFF5048E5); // primary (#5048e5)
  static const Color primaryDark = Color(0xFF3E38B3); // primary-dark
  static const Color background = Color(0xFFF8F9FC); // background-light
  static const Color white = Colors.white;

  static const Color textHeading = Color(0xFF1E1B4B); // text-main (진한 인디고)
  static const Color textBody = Color(0xFF64748B); // text-muted (Slate 500)
  static const Color borderColor = Color(0xFFE2E8F0); // Slate-200

  static const Color kakaoYellow = Color(0xFFFEE500);

  // ✍️ Text Styles
  static TextTheme textTheme = GoogleFonts.plusJakartaSansTextTheme().copyWith(
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textHeading,
      letterSpacing: -0.5,
    ),
    titleLarge: GoogleFonts.notoSansKr(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: textHeading,
    ),
    bodyMedium: GoogleFonts.notoSansKr(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textHeading,
    ),
    bodySmall: GoogleFonts.notoSansKr(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: textBody,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: white,
      surface: white,
      onSurface: textHeading,
    ),
    textTheme: textTheme,
    useMaterial3: true,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textHeading,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textHeading),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        shadowColor: primary.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
