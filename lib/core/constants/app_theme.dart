import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepTeal = Color(0xFF0D3B66);
  static const Color gold = Color(0xFFF4A261);
  static const Color cleanWhite = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF081A2C);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: deepTeal, brightness: Brightness.light).copyWith(
      primary: deepTeal,
      secondary: gold,
      surface: cleanWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cleanWhite,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: deepTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: deepTeal.withOpacity(0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: deepTeal, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: deepTeal, brightness: Brightness.dark).copyWith(
      primary: gold,
      secondary: deepTeal,
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkSurface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      cardTheme: CardTheme(
        color: const Color(0xFF0F2A44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
