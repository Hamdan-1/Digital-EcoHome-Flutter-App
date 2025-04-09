import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'models/app_state.dart';
import 'pages/splash_screen.dart';
import 'pages/dashboard_page.dart';
import 'pages/devices_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/chat_page.dart';
import 'pages/sustainability_score_page.dart';
import 'providers/theme_provider.dart';
import 'services/ai_service.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // OpenRouter API key for AI chat
  const String openRouterApiKey =
      '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';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        Provider<AiService>(
          create: (context) => AiService(apiKey: openRouterApiKey),
        ),
        ChangeNotifierProvider(create: (context) => InAppNotificationService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize theme from saved preferences
    Future.microtask(
      () =>
          Provider.of<ThemeProvider>(context, listen: false).initializeTheme(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Digital EcoHome',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  final List<Widget> _pages = [
    const DashboardPage(),
    const DevicesPage(),
    const ChatPage(),
    const ReportsPage(),
    const SettingsPage(),
    const SustainabilityScorePage(), // New Page
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    // Play animation for visual feedback
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    final primaryColor =
        isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final shadowColor =
        isDarkMode
            ? Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.1);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ), // Adjusted padding
            // Wrap the Row in a SingleChildScrollView for horizontal scrolling
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                // Use MainAxisAlignment.start since it's scrollable
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Add some padding around the items if needed
                  const SizedBox(width: 8), // Leading padding
                  _buildNavItem(0, 'Home', Icons.home),
                  _buildNavItem(1, 'Devices', Icons.devices),
                  _buildNavItem(2, 'Chat', Icons.chat_bubble_outline),
                  _buildNavItem(3, 'Reports', Icons.insert_chart),
                  _buildNavItem(4, 'Settings', Icons.settings),
                  _buildNavItem(5, 'Score', Icons.eco),
                  const SizedBox(width: 8), // Trailing padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final primaryColor =
        isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final unselectedColor =
        isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final selectedBgColor =
        isDarkMode
            ? primaryColor.withOpacity(0.15)
            : primaryColor.withOpacity(0.1);

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: Icon(
                icon,
                color: isSelected ? primaryColor : unselectedColor,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : textColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
