// lib/theme/theme.dart (COMPLETE ENHANCED VERSION WITH PERFECT COLOR COMBINATIONS)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ✅ ENHANCED: Perfect color palette with modern combinations

  // Primary Colors - Modern Blue Gradient Series
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color vibrantBlue = Color(0xFF00D2FF);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFF64B5F6);

  // Accent Colors - Vibrant & Professional
  static const Color vibrantGreen = Color(0xFF4CAF50);
  static const Color tealGreenDark = Color(0xFF00695C);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color neonGreen = Color(0xFF00E676);

  // Alert Colors - Modern & Distinctive
  static const Color darkOrangeRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color lightRed = Color(0xFFEF5350);
  static const Color criticalRed = Color(0xFFD32F2F);

  // Neutral Colors - Sophisticated Grays
  static const Color charcoalGray = Color(0xFF424242);
  static const Color mediumGray = Color(0xFF757575);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color softGray = Color(0xFFF5F5F5);

  // Dark Theme Colors - Rich & Premium
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color darkSurface = Color(0xFF162447);
  static const Color darkCard = Color(0xFF1F4068);
  static const Color darkAccent = Color(0xFF3A7BD5);

  // Gradient Colors - Beautiful Combinations
  static const List<Color> primaryGradient = [vibrantBlue, deepBlue];
  static const List<Color> successGradient = [vibrantGreen, tealGreenDark];
  static const List<Color> warningGradient = [warningOrange, darkOrangeRed];
  static const List<Color> darkGradient = [darkBackground, darkSurface, darkCard];

  // ✅ ENHANCED: Light Theme with perfect combinations
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ✅ Color Scheme - Modern & Professional
      colorScheme: const ColorScheme.light(
        primary: vibrantBlue,
        onPrimary: Colors.white,
        secondary: vibrantGreen,
        onSecondary: Colors.white,
        tertiary: warningOrange,
        onTertiary: Colors.white,
        error: darkOrangeRed,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: charcoalGray,
        background: softGray,
        onBackground: charcoalGray,
        outline: lightGray,
        outlineVariant: Color(0xFFE8E8E8),
      ),

      // ✅ App Bar Theme - Clean & Modern
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: charcoalGray,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: charcoalGray,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: charcoalGray, size: 24),
        actionsIconTheme: IconThemeData(color: charcoalGray, size: 24),
      ),

      // ✅ Card Theme - Elegant & Consistent
      cardTheme: CardThemeData(  // ✅ Changed from CardTheme
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ✅ Elevated Button Theme - Premium Feel
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vibrantBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: mediumGray,
          disabledForegroundColor: Colors.white70,
          elevation: 6,
          shadowColor: vibrantBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ✅ Outlined Button Theme - Subtle & Professional
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: vibrantBlue,
          side: const BorderSide(color: vibrantBlue, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ✅ Text Button Theme - Clean & Minimal
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: vibrantBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ✅ Input Decoration Theme - Modern & User-Friendly
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vibrantBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkOrangeRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: mediumGray, fontSize: 16),
        labelStyle: const TextStyle(color: mediumGray, fontSize: 16),
      ),

      // ✅ Bottom Navigation Bar Theme - Sleek & Intuitive
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: vibrantBlue,
        unselectedItemColor: mediumGray,
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 22),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ✅ Floating Action Button Theme - Eye-catching
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: vibrantGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),

      // ✅ Dialog Theme - Professional & Accessible
      dialogTheme: DialogThemeData(  // ✅ Changed from DialogTheme
        backgroundColor: Colors.white,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: charcoalGray,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: charcoalGray,
          fontSize: 16,
          height: 1.4,
        ),
      ),

      // ✅ Snack Bar Theme - Informative & Stylish
      snackBarTheme: SnackBarThemeData(
        backgroundColor: charcoalGray,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // ✅ Typography - Clean & Readable
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: charcoalGray,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          color: charcoalGray,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        displaySmall: TextStyle(
          color: charcoalGray,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        headlineLarge: TextStyle(
          color: charcoalGray,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: charcoalGray,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        headlineSmall: TextStyle(
          color: charcoalGray,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleLarge: TextStyle(
          color: charcoalGray,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: charcoalGray,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          color: charcoalGray,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: charcoalGray,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: mediumGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: mediumGray,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          color: charcoalGray,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: mediumGray,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: mediumGray,
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ✅ ENHANCED: Dark Theme with rich, premium colors
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ✅ Dark Color Scheme - Rich & Premium
      colorScheme: const ColorScheme.dark(
        primary: vibrantBlue,
        onPrimary: darkBackground,
        secondary: neonGreen,
        onSecondary: darkBackground,
        tertiary: warningOrange,
        onTertiary: darkBackground,
        error: lightRed,
        onError: Colors.white,
        surface: darkSurface,
        onSurface: Colors.white,
        background: darkBackground,
        onBackground: Colors.white,
        outline: Color(0xFF4A5568),
        outlineVariant: Color(0xFF2D3748),
      ),

      // ✅ Dark App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
      ),

      // ✅ Dark Card Theme
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ✅ Dark Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vibrantBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFF4A5568),
          disabledForegroundColor: Colors.white38,
          elevation: 8,
          shadowColor: vibrantBlue.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ✅ Dark Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A5568)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A5568)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vibrantBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
      ),

      // ✅ Dark Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: vibrantBlue,
        unselectedItemColor: Color(0xFF9CA3AF),
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 22),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ✅ Dark Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 20,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 16,
          height: 1.4,
        ),
      ),

      // ✅ Dark Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // ✅ Dark Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ✅ ENHANCED: Utility methods for theme operations
  static Color getTransactionTypeColor(String type, {bool isDark = false}) {
    switch (type.toLowerCase()) {
      case 'credit':
        return isDark ? neonGreen : vibrantGreen;
      case 'debit':
        return isDark ? lightRed : darkOrangeRed;
      default:
        return isDark ? Colors.white70 : mediumGray;
    }
  }

  static Color getPaymentMethodColor(String method, {bool isDark = false}) {
    switch (method.toLowerCase()) {
      case 'upi':
        return isDark ? vibrantBlue : primaryBlue;
      case 'card':
        return isDark ? warningOrange : warningOrange;
      case 'cash':
        return isDark ? neonGreen : vibrantGreen;
      default:
        return isDark ? Colors.white70 : mediumGray;
    }
  }

  static LinearGradient getStatusGradient(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'success':
        return LinearGradient(colors: isDark ? [neonGreen, vibrantGreen] : successGradient);
      case 'warning':
        return LinearGradient(colors: warningGradient);
      case 'error':
        return LinearGradient(colors: [lightRed, darkOrangeRed]);
      default:
        return LinearGradient(colors: isDark ? [vibrantBlue, deepBlue] : primaryGradient);
    }
  }

  // ✅ ENHANCED: Animation durations for consistent UX
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // ✅ ENHANCED: Border radius constants
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;

  // ✅ ENHANCED: Spacing constants
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // ✅ ENHANCED: Shadow presets
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get heavyShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ✅ ENHANCED: Gradient presets for various UI elements
  static LinearGradient get primaryCardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [vibrantBlue, deepBlue],
  );

  static LinearGradient get successCardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [vibrantGreen, tealGreenDark],
  );

  static LinearGradient get warningCardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningOrange, darkOrangeRed],
  );

  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [softGray, Colors.white],
  );

  static LinearGradient get darkBackgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBackground, darkSurface],
  );
}
