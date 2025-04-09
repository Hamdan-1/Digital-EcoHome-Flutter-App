import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_themes.dart'; // Import the new themes file

class ThemeProvider extends ChangeNotifier {
  // Key to store theme preference
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _themeKey = 'selected_theme_key'; // Key for selected theme

  // Theme mode and selected theme
  bool _isDarkMode = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  String _selectedThemeKey = AppThemes.themeKeys.first; // Default to the first theme key

  ThemeProvider() {
    // Load theme preference from storage when initialized
    _loadThemePreference();
  }

  // Getter for dark mode state
  bool get isDarkMode => _isDarkMode;

  // Getter for current theme
  // Getter for current theme based on selected key and dark mode
  ThemeData get currentTheme => AppThemes.getThemeData(
      _selectedThemeKey, _isDarkMode ? Brightness.dark : Brightness.light);

  // Getter for the list of available theme keys
  List<String> get availableThemeKeys => AppThemes.themeKeys;

  // Getter for the currently selected theme key
  String get selectedThemeKey => _selectedThemeKey;

  // Initialize theme from saved preferences - called from main.dart
  Future<void> initializeTheme() async {
    await _loadThemePreference();
  }

  // Toggle dark mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  // Set dark mode specifically
  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      _saveThemePreference();
      notifyListeners();
    }
  }

  // Load theme preferences (dark mode and selected theme key)
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load dark mode, default based on system if not set
      _isDarkMode = prefs.getBool(_darkModeKey) ??
          (SchedulerBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);
      // Load selected theme key, default to first available key if not set
      _selectedThemeKey = prefs.getString(_themeKey) ?? AppThemes.themeKeys.first;

      // Ensure the loaded key is valid, otherwise reset to default
      if (!AppThemes.themeKeys.contains(_selectedThemeKey)) {
        _selectedThemeKey = AppThemes.themeKeys.first;
        // Optionally save the reset default back to prefs
        await prefs.setString(_themeKey, _selectedThemeKey);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme preferences: $e');
      // Set defaults in case of error
      _isDarkMode = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      _selectedThemeKey = AppThemes.themeKeys.first;
      notifyListeners(); // Notify even on error to apply defaults
    }
  }

  // Save theme preferences (dark mode and selected theme key)
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
      await prefs.setString(_themeKey, _selectedThemeKey);
    } catch (e) {
      debugPrint('Failed to save theme preferences: $e');
    }
  }

  // Set the selected theme
  void setTheme(String themeKey) {
    if (AppThemes.themeKeys.contains(themeKey) && _selectedThemeKey != themeKey) {
      _selectedThemeKey = themeKey;
      _saveThemePreference(); // Save both theme key and current dark mode state
      notifyListeners();
    }
  }
}
