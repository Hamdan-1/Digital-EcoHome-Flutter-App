import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../main.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';
import '../utils/custom_page_transitions.dart'; // Import custom transitions

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _loadingAnimationController;
  @override
  void initState() {
    super.initState();

    // Initialize main animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    // Initialize loading animation
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(); // Start animation and navigate to home after delay
    _animationController.forward();
    Timer(const Duration(seconds: 3), () {
      // Replace PageRouteBuilder with custom transition extension
      context.pushPageWithTransition(
        page: const MainNavigation(),
        transitionType: TransitionType.fade, // Use standard fade
        replace: true, // Replace the splash screen
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Set system overlay style for status bar based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo goes here - choosing based on current theme
                    Image.asset(
                      isDarkMode
                          ? 'Digital EcoHome Logo dark Mode.png'
                          : 'Digital EcoHome logo Light Mode.png',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Digital EcoHome',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode
                                ? AppTheme.darkPrimaryColor
                                : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart Living, Sustainable Future',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isDarkMode
                                ? AppTheme.darkTextSecondaryColor
                                : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
