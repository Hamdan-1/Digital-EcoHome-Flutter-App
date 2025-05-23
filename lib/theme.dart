import 'package:flutter/material.dart';

class AppTheme {
  // App theme colors
  static const Color primaryColor = Color(0xFF4CAF50); // eco-green
  static const Color secondaryColor = Color(
    0xFF2196F3,
  ); // blue for water/energy
  static const Color backgroundColor = Color(0xFFF5F7FA); // light background
  static const Color textPrimaryColor = Color(
    0xFF2D3748,
  ); // dark gray for primary text
  static const Color textSecondaryColor = Color(
    0xFF718096,
  ); // lighter gray for secondary text
  static const Color successColor = Color(0xFF388E3C); // Green 700
  static const Color errorColor = Color(0xFFD32F2F);   // Red 700

  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF43A047); // darker eco-green
  static const Color darkSecondaryColor = Color(0xFF1E88E5); // deeper blue
  static const Color darkBackgroundColor = Color(
    0xFF121212,
  ); // material dark background
  static const Color darkCardColor = Color(
    0xFF1E1E1E,
  ); // slightly lighter than background
  static const Color darkTextPrimaryColor = Color(
    0xFFE0E0E0,
  ); // light gray for primary text
  static const Color darkTextSecondaryColor = Color(
    0xFFAAAAAA,
  ); // medium gray for secondary text
  // Using the same success/error colors for dark theme as they have sufficient contrast
  static const Color darkSuccessColor = Color(0xFF388E3C); // Green 700
  static const Color darkErrorColor = Color(0xFFD32F2F);   // Red 700

  // Light theme for the app
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor, // Replaced deprecated 'background'
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFFA0AEC0),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimaryColor),
      displayMedium: TextStyle(color: textPrimaryColor),
      displaySmall: TextStyle(color: textPrimaryColor),
      headlineMedium: TextStyle(color: textPrimaryColor),
      headlineSmall: TextStyle(color: textPrimaryColor),
      titleLarge: TextStyle(color: textPrimaryColor),
      bodyLarge: TextStyle(color: textPrimaryColor),
      bodyMedium: TextStyle(color: textPrimaryColor),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  // Dark theme for the app
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: darkPrimaryColor,
    colorScheme: ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
      surface: darkBackgroundColor, // Replaced deprecated 'background'
      onSurface: darkTextPrimaryColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: darkPrimaryColor,
      unselectedItemColor: Color(0xFF777777),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkTextPrimaryColor),
      displayMedium: TextStyle(color: darkTextPrimaryColor),
      displaySmall: TextStyle(color: darkTextPrimaryColor),
      headlineMedium: TextStyle(color: darkTextPrimaryColor),
      headlineSmall: TextStyle(color: darkTextPrimaryColor),
      titleLarge: TextStyle(color: darkTextPrimaryColor),
      bodyLarge: TextStyle(color: darkTextPrimaryColor),
      bodyMedium: TextStyle(color: darkTextPrimaryColor),
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: darkPrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return darkPrimaryColor;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return darkPrimaryColor.withAlpha((0.5 * 255).round());
        }
        return Colors.grey.withAlpha((0.5 * 255).round());
      }),
    ),
    iconTheme: const IconThemeData(color: darkTextPrimaryColor),
  );

  // A class to manage the theme mode
  static bool _isDarkMode = false;

  static bool get isDarkMode => _isDarkMode;

  static void toggleTheme() {
    _isDarkMode = !_isDarkMode;
  }

  static ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Helper methods to get the correct color based on the current theme mode
  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimaryColor
        : textPrimaryColor;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondaryColor
        : textSecondaryColor;
  }

  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimaryColor
        : primaryColor;
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondaryColor
        : secondaryColor;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardColor
        : Colors.white;
  }

  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSuccessColor
        : successColor;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkErrorColor
        : errorColor;
  }
}
