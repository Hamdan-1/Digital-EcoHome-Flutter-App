import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ThemeProvider extends ChangeNotifier {
  // Key to store theme preference
  static const String _darkModeKey = 'dark_mode_enabled';

  // Theme mode
  bool _isDarkMode = false;

  ThemeProvider() {
    // Load theme preference from storage when initialized
    _loadThemePreference();
  }

  // Getter for dark mode state
  bool get isDarkMode => _isDarkMode;

  // Getter for current theme
  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

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

  // Load theme preference from persistent storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme preference: $e');
    }
  }

  // Save theme preference to persistent storage
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
}
