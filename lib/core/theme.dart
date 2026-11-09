import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna diambil dari desain Figma (Login: #10B3A3, tombol: #1E1E1E).
class AppColors {
  static const teal = Color(0xFF10B3A3);
  static const tealDark = Color(0xFF0E9588);
  static const tealSoft = Color(0xFFD6F0EC);
  static const ink = Color(0xFF1E1E1E);
  static const navy = Color(0xFF0F1B2D);
  static const lime = Color(0xFFD9F24C);
  static const bg = Color(0xFFF1F6F5);
  static const field = Color(0xFFE5E5E5);
  static const danger = Color(0xFFD64545);
  static const muted = Color(0xFF6B7B7A);
}

TextStyle _font(String family, double size, FontWeight weight, Color color) {
  try {
    return GoogleFonts.getFont(family,
        fontSize: size, fontWeight: weight, color: color);
  } catch (_) {
    return GoogleFonts.poppins(
        fontSize: size, fontWeight: weight, color: color);
  }
}

class AppText {
  /// Judul: Momo Trust Display
  static TextStyle heading(double size, {Color color = AppColors.ink}) =>
      _font('Momo Trust Display', size, FontWeight.w400, color);

  /// Teks isi: Open Sans
  static TextStyle body(double size,
          {FontWeight weight = FontWeight.w400, Color color = AppColors.ink}) =>
      _font('Open Sans', size, weight, color);

  /// Label form: Ancizar Sans
  static TextStyle label(double size, {Color color = AppColors.ink}) =>
      _font('Ancizar Sans', size, FontWeight.w400, color);

  /// Logo: Poppins Black
  static TextStyle logo(double size, {Color color = Colors.black}) =>
      _font('Poppins', size, FontWeight.w900, color);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
    ),
    textTheme: GoogleFonts.openSansTextTheme(),
  );
}
