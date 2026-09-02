import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtlasColors {
  static const Color blue = Color(0xFF0B192C); // Deep Blue Primary
  static const Color blueLight = Color(
    0xFF1A365D,
  ); // Lighter blue for active states
  static const Color surface = Color(0xFFFDFCFB); // Warm white background
  static const Color surfaceDark = Color(0xFF121212); // Dark mode background
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color purple = Color(0xFF9333EA); // AI Accent
  static const Color emerald = Color(0xFF10B981); // Success accent
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color amber = Color(0xFFF59E0B); // Warning
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color rose = Color(0xFFEF4444); // Error
  static const Color roseLight = Color(0xFFFEE2E2);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFF3F4F6);
}

class AtlasTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AtlasColors.surface,
      primaryColor: AtlasColors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AtlasColors.blue,
        primary: AtlasColors.blue,
        secondary: AtlasColors.purple,
        surface: AtlasColors.surface,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AtlasColors.textPrimary,
        displayColor: AtlasColors.blue,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AtlasColors.blue),
        titleTextStyle: GoogleFonts.outfit(
          color: AtlasColors.blue,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  static BoxShadow get floatShadow => BoxShadow(
    color: AtlasColors.blue.withValues(alpha: 0.15),
    blurRadius: 32,
    offset: const Offset(0, 12),
  );
}
