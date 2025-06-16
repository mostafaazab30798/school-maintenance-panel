import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.indigo,
    primaryColor: const Color(0xFF3B82F6),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardColor: Colors.white,
    fontFamily: GoogleFonts.cairo().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.cairo(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
        fontSize: 22,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF1E293B),
      ),
    ),
    textTheme: _buildLightTextTheme(),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF10B981),
      surface: Colors.white,
      background: Color(0xFFF8FAFC),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.indigo,
    primaryColor: const Color(0xFF60A5FA),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardColor: const Color(0xFF1E293B),
    fontFamily: GoogleFonts.cairo().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.cairo(
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF1F5F9),
        fontSize: 22,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFF1F5F9),
      ),
    ),
    textTheme: _buildDarkTextTheme(),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF60A5FA),
      secondary: Color(0xFF34D399),
      surface: Color(0xFF1E293B),
      background: Color(0xFF0F172A),
    ),
  );

  // Light theme text styles using Arabic fonts
  static TextTheme _buildLightTextTheme() {
    return GoogleFonts.cairoTextTheme().copyWith(
      // Display styles
      displayLarge: GoogleFonts.cairo(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1E293B),
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1E293B),
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.cairo(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1E293B),
        letterSpacing: 0,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
        letterSpacing: 0,
      ),

      // Title styles
      titleLarge: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
        letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
        letterSpacing: 0.1,
      ),

      // Body styles
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF334155),
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF475569),
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF64748B),
        letterSpacing: 0.4,
      ),

      // Label styles
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  // Dark theme text styles using Arabic fonts
  static TextTheme _buildDarkTextTheme() {
    return GoogleFonts.cairoTextTheme().copyWith(
      // Display styles
      displayLarge: GoogleFonts.cairo(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFF1F5F9),
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFF1F5F9),
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.cairo(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFF1F5F9),
        letterSpacing: 0,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF1F5F9),
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF1F5F9),
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF1F5F9),
        letterSpacing: 0,
      ),

      // Title styles
      titleLarge: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF1F5F9),
        letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF1F5F9),
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFCBD5E1),
        letterSpacing: 0.1,
      ),

      // Body styles
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFE2E8F0),
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFCBD5E1),
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.4,
      ),

      // Label styles
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFCBD5E1),
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }
}
