import 'package:flutter/material.dart';

/// App theme configuration - Dark theme with ghost purple accent
class AppTheme {
  // Color palette
  static const Color primaryBlack = Color(0xFF141414);
  static const Color surfaceBlack = Color(0xFF1A1A1A);
  static const Color cardBlack = Color(0xFF232323);
  static const Color accentPurple = Color(0xFF8B5CF6); // Ghost purple
  static const Color accentPurpleLight = Color(0xFFA78BFA); // Lighter purple
  static const Color accentPurpleDark = Color(0xFF7C3AED); // Deeper purple
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFA0A0A0);
  static const Color textGreyLight = Color(0xFFB3B3B3);
  static const Color dividerColor = Color(0xFF2A2A2A);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x99141414), // 60%
      primaryBlack, // 100%
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Card dimensions
  static const double mangaCardWidth = 130.0;
  static const double mangaCardHeight = 190.0;
  static const double heroHeight = 450.0;

  // Animations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Theme data
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryBlack,
    colorScheme: const ColorScheme.dark(
      primary: accentPurple,
      secondary: accentPurpleLight,
      surface: surfaceBlack,
      error: Colors.redAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textWhite,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textWhite),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceBlack,
      selectedItemColor: accentPurple,
      unselectedItemColor: textGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: cardBlack,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textWhite, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textWhite, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textWhite, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: textGreyLight),
      bodyLarge: TextStyle(color: textWhite),
      bodyMedium: TextStyle(color: textGreyLight),
      bodySmall: TextStyle(color: textGrey),
      labelLarge: TextStyle(color: textWhite, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: textGreyLight),
      labelSmall: TextStyle(color: textGrey),
    ),
    iconTheme: const IconThemeData(color: textWhite),
    dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
  );
}
