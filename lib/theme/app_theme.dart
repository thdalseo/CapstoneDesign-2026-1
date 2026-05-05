import 'package:flutter/material.dart';

class AppTheme {
  // 컬러
  static const Color primary = Color(0xFF4C80AF);
  static const Color mint = Color(0xFF3ABBA0);
  static const Color coral = Color(0xFFFF8E7A);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E8F0);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          background: background,
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'Pretendard',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFFBBBBBB),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      );
}