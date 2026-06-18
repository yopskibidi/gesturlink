import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistem desain GesturLink — terinspirasi dari Linear, Vercel, Apple.
/// Prinsip: minimal, presisi, konsisten, dan elegan.
class AppTheme {
  // ── Sistem Warna ──
  static const Color bg = Color(0xFF09090B);           // Latar utama
  static const Color bgElevated = Color(0xFF0F1115);   // Permukaan terangkat
  static const Color bgCard = Color(0xFF141519);       // Kartu
  static const Color bgHover = Color(0xFF1A1B21);      // Hover state

  static const Color border = Color(0xFF27272A);       // Border standar
  static const Color borderFocus = Color(0xFF3B82F6);  // Border fokus (biru)

  static const Color accent = Color(0xFF3B82F6);       // Biru utama
  static const Color accentSoft = Color(0xFF1D4ED8);   // Biru gelap
  static const Color success = Color(0xFF22C55E);      // Hijau
  static const Color warning = Color(0xFFF59E0B);      // Kuning
  static const Color danger = Color(0xFFEF4444);       // Merah

  static const Color text = Color(0xFFFAFAFA);         // Teks utama
  static const Color textSub = Color(0xFFA1A1AA);      // Teks sekunder
  static const Color textMuted = Color(0xFF52525B);    // Teks redup

  // ── Sistem Spasi ──
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  // ── Radius ──
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r16 = 16;

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentSoft,
        surface: bgElevated,
        onSurface: text,
      ),
      textTheme: baseText.copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 30, fontWeight: FontWeight.w700, color: text, height: 1.2,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600, color: text, height: 1.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: text,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400, color: textSub, height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: textSub, height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, color: textMuted,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: textMuted, letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: text, fontSize: 16, fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textSub, size: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          elevation: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: GoogleFonts.inter(color: text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
