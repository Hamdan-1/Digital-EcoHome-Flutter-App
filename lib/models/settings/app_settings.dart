// File: app_settings.dart
// Main settings model for the Digital EcoHome app

import 'user_preferences.dart';
import 'home_configuration.dart';
import 'device_management.dart';
import 'advanced_settings.dart';

class AppSettings {
  // User preferences section
  UserPreferences userPreferences;

  // Home configuration section
  HomeConfiguration homeConfiguration;

  // Device management section
  DeviceManagement deviceManagement;

  // Advanced settings section
  AdvancedSettings advancedSettings;

  // Help & information
  AboutSettings aboutSettings;

  // Default constructor with initial values
  AppSettings({
    UserPreferences? userPreferences,
    HomeConfiguration? homeConfiguration,
    DeviceManagement? deviceManagement,
    AdvancedSettings? advancedSettings,
    AboutSettings? aboutSettings,
  }) : userPreferences = userPreferences ?? UserPreferences(),
       homeConfiguration = homeConfiguration ?? HomeConfiguration(),
       deviceManagement = deviceManagement ?? DeviceManagement(),
       advancedSettings = advancedSettings ?? AdvancedSettings(),
       aboutSettings = aboutSettings ?? AboutSettings();

  // Create a copy with modified values
  AppSettings copyWith({
    UserPreferences? userPreferences,
    HomeConfiguration? homeConfiguration,
    DeviceManagement? deviceManagement,
    AdvancedSettings? advancedSettings,
    AboutSettings? aboutSettings,
  }) {
    return AppSettings(
      userPreferences: userPreferences ?? this.userPreferences,
      homeConfiguration: homeConfiguration ?? this.homeConfiguration,
      deviceManagement: deviceManagement ?? this.deviceManagement,
      advancedSettings: advancedSettings ?? this.advancedSettings,
      aboutSettings: aboutSettings ?? this.aboutSettings,
    );
  }
}

// About and help information
class AboutSettings {
  String appVersion;
  String buildNumber;
  List<FAQItem> faqItems;
  List<TutorialScreen> tutorialScreens;
  String privacyPolicyUrl;
  String termsOfServiceUrl;
  String supportEmail;
  String websiteUrl;

  // Default constructor with initial values
  AboutSettings({
    this.appVersion = '1.0.0',
    this.buildNumber = '1',
    List<FAQItem>? faqItems,
    List<TutorialScreen>? tutorialScreens,
    this.privacyPolicyUrl = 'https://digitalecohome.example.com/privacy',
    this.termsOfServiceUrl = 'https://digitalecohome.example.com/terms',
    this.supportEmail = 'support@digitalecohome.example.com',
    this.websiteUrl = 'https://digitalecohome.example.com',
  }) : faqItems = faqItems ?? _getDefaultFAQItems(),
       tutorialScreens = tutorialScreens ?? _getDefaultTutorialScreens();

  // Default FAQ items
  static List<FAQItem> _getDefaultFAQItems() {
    return [
      FAQItem(
        question: 'What is Digital EcoHome?',
        answer:
            'Digital EcoHome is an application designed to help you monitor, analyze, and optimize your home\'s energy usage. It connects to smart devices in your home to provide real-time energy consumption data and suggestions for energy savings.',
      ),
      FAQItem(
        question: 'How accurate is the energy usage data?',
        answer:
            'The accuracy of energy usage data depends on the devices connected. For now, the app uses simulated data, but in the future, with proper IoT integration, the data can be very accurate, typically within 5-10% of your actual energy consumption.',
      ),
      FAQItem(
        question: 'How can I add new devices?',
        answer:
            'Navigate to the Devices tab and tap on the "+" button in the top-right corner. You can then scan for new devices or manually add them by following the on-screen instructions.',
      ),
      FAQItem(
        question: 'What is the energy goal feature?',
        answer:
            'Energy goals allow you to set targets for your monthly energy consumption. The app will track your progress and send notifications to help you stay within your desired energy usage limits.',
      ),
      FAQItem(
        question: 'Can I export my energy usage data?',
        answer:
            'Yes, in the Reports section, you can generate reports of your energy usage and export them as CSV or PDF files for your records or for sharing with others.',
      ),
    ];
  }

  // Default tutorial screens
  static List<TutorialScreen> _getDefaultTutorialScreens() {
    return [
      TutorialScreen(
        title: 'Welcome to Digital EcoHome',
        description: 'Your smart solution for home energy management',
        imageAsset: 'assets/tutorial/welcome.png',
      ),
      TutorialScreen(
        title: 'Monitor Your Energy',
        description:
            'See real-time energy usage for all your connected devices',
        imageAsset: 'assets/tutorial/monitor.png',
      ),
      TutorialScreen(
        title: 'Set Energy Goals',
        description: 'Create and track energy saving goals for your household',
        imageAsset: 'assets/tutorial/goals.png',
      ),
      TutorialScreen(
        title: 'Get Insights',
        description:
            'Receive personalized tips and recommendations to reduce energy waste',
        imageAsset: 'assets/tutorial/insights.png',
      ),
      TutorialScreen(
        title: 'Complete Control',
        description:
            'Manage your devices remotely and schedule energy-saving routines',
        imageAsset: 'assets/tutorial/control.png',
      ),
    ];
  }
}

// FAQ item model
class FAQItem {
  String question;
  String answer;

  FAQItem({required this.question, required this.answer});
}

// Tutorial screen model
class TutorialScreen {
  String title;
  String description;
  String imageAsset;

  TutorialScreen({
    required this.title,
    required this.description,
    required this.imageAsset,
  });
}
