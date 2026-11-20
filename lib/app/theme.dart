import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Couleurs de la marque, estimées d'après le logo (à confirmer avec le fichier source).
class Brand {
  Brand._();

  static const Color blue = Color(0xFF0B4DA2);
  static const Color navy = Color(0xFF0A2A66);
  static const Color red = Color(0xFFE10A2D);
  static const Color yellow = Color(0xFFFFC21A);
  static const Color paper = Color(0xFFF5F7FB);
  static const Color line = Color(0xFFDDE3EE);
  static const Color ink = Color(0xFF1B2433);
  static const Color muted = Color(0xFF475569);
  static const Color mapPin = Color(0xFF8FB2EE);
  static const Color whatsapp = Color(0xFF1A7F45);
}

/// Titres : police grasse et condensée, proche des affiches du média.
TextStyle displayStyle(
  double size, {
  Color color = Brand.navy,
  double height = 1.0,
}) {
  return GoogleFonts.barlowCondensed(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    height: height,
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Brand.blue,
      primary: Brand.blue,
      secondary: Brand.red,
    ),
    scaffoldBackgroundColor: Brand.paper,
  );
  return base.copyWith(
    textTheme: GoogleFonts.sourceSans3TextTheme(base.textTheme).apply(
      bodyColor: Brand.ink,
      displayColor: Brand.ink,
    ),
  );
}
