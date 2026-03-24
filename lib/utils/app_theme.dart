// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neural Spark palette — deep navy + cyan + purple
  static const Color primary     = Color(0xFF00C9FF); // cyan
  static const Color primaryDark = Color(0xFF0099CC);
  static const Color secondary   = Color(0xFF7B5EA7); // purple
  static const Color accent      = Color(0xFF00E5FF);

  static const Color bgDark    = Color(0xFF090E1A); // deep navy-black
  static const Color bgCard    = Color(0xFF0F1628); // card navy
  static const Color bgSurface = Color(0xFF141D35); // surface
  static const Color bgInput   = Color(0xFF1A2340); // input

  static const Color userBubble = Color(0xFF1A3A6B); // navy user bubble
  static const Color aiBubble   = Color(0xFF0F1628);

  static const Color textPrimary   = Color(0xFFE8F4FF); // cool white
  static const Color textSecondary = Color(0xFF7A9CC4); // muted blue
  static const Color textHint      = Color(0xFF3A5070); // hint

  static const Color divider = Color(0xFF1E2D45);
  static const Color error   = Color(0xFFFF4C6A);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: bgCard,
          error: error,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyLarge:   GoogleFonts.dmSans(color: textPrimary,   fontSize: 15),
          bodyMedium:  GoogleFonts.dmSans(color: textPrimary,   fontSize: 14),
          bodySmall:   GoogleFonts.dmSans(color: textSecondary, fontSize: 12),
          titleLarge:  GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark, elevation: 0, centerTitle: true,
          iconTheme: IconThemeData(color: textPrimary),
        ),
        iconTheme: const IconThemeData(color: textSecondary),
        dividerTheme: const DividerThemeData(color: divider),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: bgInput,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: primary, width: 1.5)),
          hintStyle: GoogleFonts.dmSans(color: textHint, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      );
  static Color getBubbleColor(BuildContext context, bool isUser) {
    return isUser ? userBubble : aiBubble;
  }
}