import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData oceanBreezeLight = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue[600],
    scaffoldBackgroundColor: Colors.lightBlue[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.blue[600]!,
      secondary: Colors.cyan[600]!,
      surface: Colors.white,
      background: Colors.lightBlue[50]!,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.cyan[600],
    ),
    useMaterial3: true,
  );

  static final ThemeData oceanBreezeDark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue[300],
    scaffoldBackgroundColor: Colors.blueGrey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueGrey[800],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[300]!,
      secondary: Colors.cyan[300]!,
      surface: Colors.blueGrey[800]!,
      background: Colors.blueGrey[900]!,
      error: Colors.redAccent[100]!,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    cardTheme: CardTheme(
      color: Colors.blueGrey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.cyan[300],
    ),
    useMaterial3: true,
  );

  static final ThemeData forestCanopyLight = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    primaryColor: Colors.green[700],
    scaffoldBackgroundColor: Colors.lightGreen[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green[800],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.green[700]!,
      secondary: Colors.brown[400]!,
      surface: Colors.white,
      background: Colors.lightGreen[50]!,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.brown[400],
    ),
    useMaterial3: true,
  );

  static final ThemeData forestCanopyDark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    primaryColor: Colors.green[300],
    scaffoldBackgroundColor: Color(0xFF1B2E1F), // Dark green-ish grey
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green[900],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.green[300]!,
      secondary: Colors.brown[300]!,
      surface: Color(0xFF2C3E31), // Slightly lighter dark green-ish grey
      background: Color(0xFF1B2E1F),
      error: Colors.redAccent[100]!,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    cardTheme: CardTheme(
      color: Color(0xFF2C3E31),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.brown[300],
    ),
    useMaterial3: true,
  );

  static final ThemeData sunsetGlowLight = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.orange,
    primaryColor: Colors.deepOrange[500],
    scaffoldBackgroundColor: Colors.orange[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepOrange[600],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.deepOrange[500]!,
      secondary: Colors.amber[700]!,
      surface: Colors.white,
      background: Colors.orange[50]!,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.amber[700],
    ),
    useMaterial3: true,
  );

  static final ThemeData sunsetGlowDark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.orange,
    primaryColor: Colors.orange[300],
    scaffoldBackgroundColor: Color(0xFF3E2723), // Dark brown
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepOrange[800],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.orange[300]!,
      secondary: Colors.amber[300]!,
      surface: Color(0xFF4E342E), // Slightly lighter dark brown
      background: Color(0xFF3E2723),
      error: Colors.redAccent[100]!,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    cardTheme: CardTheme(
      color: Color(0xFF4E342E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.amber[300],
    ),
    useMaterial3: true,
  );


  // New Purple Theme - Midnight Dusk Light
  static final ThemeData midnightDuskLight = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.purple,
    primaryColor: Colors.deepPurple[500],
    scaffoldBackgroundColor: Colors.purple[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple[600],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.deepPurple[500]!,
      secondary: Colors.pinkAccent[100]!,
      surface: Colors.white,
      background: Colors.purple[50]!,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.pinkAccent[100],
    ),
    useMaterial3: true,
  );

  // New Purple Theme - Midnight Dusk Dark
  static final ThemeData midnightDuskDark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.purple,
    primaryColor: Colors.purple[300],
    scaffoldBackgroundColor: Color(0xFF2C1B2E), // Dark purple-ish grey
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple[800],
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.purple[300]!,
      secondary: Colors.pinkAccent[200]!, // Adjusted for dark mode visibility
      surface: Color(0xFF3E2C3F), // Slightly lighter dark purple-ish grey
      background: Color(0xFF2C1B2E),
      error: Colors.redAccent[100]!,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    cardTheme: CardTheme(
      color: Color(0xFF3E2C3F),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.pinkAccent[200],
    ),
    useMaterial3: true,
  );

  // Add more themes like Midnight Dusk if desired

  static Map<String, ThemeData> get lightThemes => {
    'Ocean Breeze': oceanBreezeLight,
    'Forest Canopy': forestCanopyLight,
    'Sunset Glow': sunsetGlowLight,
    'Midnight Dusk': midnightDuskLight,
    // Add default light theme if needed
    'Default Light': ThemeData.light(useMaterial3: true),
  };

  static Map<String, ThemeData> get darkThemes => {
    'Ocean Breeze': oceanBreezeDark,
    'Forest Canopy': forestCanopyDark,
    'Sunset Glow': sunsetGlowDark,
    'Midnight Dusk': midnightDuskDark,
    // Add default dark theme if needed
    'Default Dark': ThemeData.dark(useMaterial3: true),
  };

  static ThemeData getThemeData(String key, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return darkThemes[key] ??
          ThemeData.dark(useMaterial3: true); // Fallback to default dark
    } else {
      return lightThemes[key] ??
          ThemeData.light(useMaterial3: true); // Fallback to default light
    }
  }

  static List<String> get themeKeys =>
      lightThemes.keys.toList(); // Assuming keys are same for light/dark
}
