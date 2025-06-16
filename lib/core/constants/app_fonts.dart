import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class for Arabic fonts using Cairo font only
class AppFonts {
  // Private constructor to prevent instantiation
  AppFonts._();

  /// Cairo font family - Modern, clean, widely used for Arabic
  static String get cairo => GoogleFonts.cairo().fontFamily!;

  // Common text styles using Arabic fonts

  /// App Bar Title Style
  static TextStyle appBarTitle({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color:
          color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      letterSpacing: -0.3,
    );
  }

  /// Page Header Style
  static TextStyle pageHeader({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color:
          color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      letterSpacing: -0.4,
    );
  }

  /// Section Title Style
  static TextStyle sectionTitle({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color:
          color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      letterSpacing: -0.2,
    );
  }

  /// Card Title Style
  static TextStyle cardTitle({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color:
          color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      letterSpacing: 0.1,
    );
  }

  /// Subtitle Style
  static TextStyle subtitle({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color:
          color ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
      letterSpacing: 0.1,
    );
  }

  /// Body Text Style
  static TextStyle bodyText({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color:
          color ?? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
      letterSpacing: 0.25,
      height: 1.5,
    );
  }

  /// Small Body Text Style
  static TextStyle bodySmall({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color:
          color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      letterSpacing: 0.4,
      height: 1.4,
    );
  }

  /// Caption Style
  static TextStyle caption({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color:
          color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      letterSpacing: 0.5,
    );
  }

  /// Button Text Style
  static TextStyle buttonText({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
      letterSpacing: 0.1,
    );
  }

  /// Input Label Style
  static TextStyle inputLabel({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color:
          color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      letterSpacing: 0.4,
    );
  }

  /// Input Text Style
  static TextStyle inputText({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color:
          color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      letterSpacing: 0.1,
    );
  }

  /// Error Text Style
  static TextStyle errorText({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color ?? const Color(0xFFEF4444),
      letterSpacing: 0.25,
    );
  }

  /// Success Text Style
  static TextStyle successText({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color ?? const Color(0xFF10B981),
      letterSpacing: 0.25,
    );
  }

  /// Warning Text Style
  static TextStyle warningText({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color ?? const Color(0xFFF59E0B),
      letterSpacing: 0.25,
    );
  }

  /// Number/Stat Text Style (for displaying numbers, dates, etc.)
  static TextStyle statText({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color:
          color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      letterSpacing: -0.5,
    );
  }

  /// Large Number/Stat Text Style
  static TextStyle largeStat({Color? color, bool isDark = false}) {
    return GoogleFonts.cairo(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color:
          color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      letterSpacing: -0.8,
    );
  }
}
