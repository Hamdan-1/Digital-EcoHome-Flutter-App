// File: user_preferences.dart
// Contains user preference settings for the Digital EcoHome app

class UserPreferences {
  // Energy cost settings
  double energyPricePerKwh;
  String currency;

  // Temperature unit preference (Celsius/Fahrenheit)
  String temperatureUnit;

  // Notification preferences
  bool notificationsEnabled;
  bool energyAlertNotifications;
  bool deviceStatusNotifications;
  bool weeklyReportNotifications;
  bool tipsAndSuggestionsNotifications;

  // Dark mode preference
  bool darkModeEnabled;

  // Auto refresh preference
  bool autoUpdateEnabled;

  // Default constructor with initial values
  UserPreferences({
    this.energyPricePerKwh = 0.15,
    this.currency = 'USD',
    this.temperatureUnit = 'Celsius',
    this.notificationsEnabled = true,
    this.energyAlertNotifications = true,
    this.deviceStatusNotifications = true,
    this.weeklyReportNotifications = true,
    this.tipsAndSuggestionsNotifications = true,
    this.darkModeEnabled = false,
    this.autoUpdateEnabled = true,
  });

  // Create a copy with modified values
  UserPreferences copyWith({
    double? energyPricePerKwh,
    String? currency,
    String? temperatureUnit,
    bool? notificationsEnabled,
    bool? energyAlertNotifications,
    bool? deviceStatusNotifications,
    bool? weeklyReportNotifications,
    bool? tipsAndSuggestionsNotifications,
    bool? darkModeEnabled,
    bool? autoUpdateEnabled,
  }) {
    return UserPreferences(
      energyPricePerKwh: energyPricePerKwh ?? this.energyPricePerKwh,
      currency: currency ?? this.currency,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      energyAlertNotifications:
          energyAlertNotifications ?? this.energyAlertNotifications,
      deviceStatusNotifications:
          deviceStatusNotifications ?? this.deviceStatusNotifications,
      weeklyReportNotifications:
          weeklyReportNotifications ?? this.weeklyReportNotifications,
      tipsAndSuggestionsNotifications:
          tipsAndSuggestionsNotifications ??
          this.tipsAndSuggestionsNotifications,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
    );
  }

  // List of available currencies
  static List<String> get availableCurrencies => [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CNY',
    'INR',
    'AED',
    'SAR',
  ];

  // List of available temperature units
  static List<String> get availableTemperatureUnits => [
    'Celsius',
    'Fahrenheit',
  ];
}
