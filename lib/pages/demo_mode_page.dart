import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/demo_mode.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/demo_control_panel.dart';
import 'dashboard_page.dart';
import 'devices_page.dart';
import 'chat_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'sustainability_score_page.dart';

class DemoModePage extends StatefulWidget {
  const DemoModePage({Key? key}) : super(key: key);

  @override
  State<DemoModePage> createState() => _DemoModePageState();
}

class _DemoModePageState extends State<DemoModePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  bool _autoAdvance = false;
  
  // Keys for highlighting specific UI elements during the demo
  final Map<String, GlobalKey> _highlightKeys = {
    'dashboard_usage_chart': GlobalKey(),
    'dashboard_alerts': GlobalKey(),
    'device_list': GlobalKey(),
    'recommendations': GlobalKey(),
    'sustainability_score': GlobalKey(),
    'energy_saving_tips': GlobalKey(),
  };

  // Pages that will be shown during the demo
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );    // Initialize the pages
    _pages = [
      const DashboardPage(), // Use regular constructor but track the keys in the demo overlay
      const DevicesPage(),
      const ChatPage(),
      const ReportsPage(),
      const SustainabilityScorePage(),
      const SettingsPage(),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    // Play animation for visual feedback
    _animationController.reset();
    _animationController.forward();
  }
    // Handle toggling auto-advance mode
  void _toggleAutoAdvance(bool value) {
    setState(() {
      _autoAdvance = value;
    });
    
    // Since setAutoAdvance might not be implemented in DemoMode yet,
    // we'll handle it directly here
    final demoMode = Provider.of<DemoMode>(context, listen: false);
    if (value && demoMode.currentStep < demoMode.totalSteps - 1) {
      // Start auto-advancing
      Future.delayed(const Duration(seconds: 5), () {
        if (_autoAdvance && mounted) {
          demoMode.nextStep();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = Provider.of<DemoMode>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Automatically navigate to appropriate page based on demo state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (demoMode.currentState) {
        case DemoState.introduction:
          if (_currentIndex != 0) _navigateToPage(0); // Dashboard for intro
          break;
        case DemoState.dashboardOverview:
          if (_currentIndex != 0) _navigateToPage(0); // Dashboard
          break;
        case DemoState.energySpike:
          if (_currentIndex != 0) _navigateToPage(0); // Dashboard to show spike
          break;
        case DemoState.deviceControl:
          if (_currentIndex != 1) _navigateToPage(1); // Devices
          break;
        case DemoState.smartRecommendation:
          if (_currentIndex != 2) _navigateToPage(2); // Chat/AI
          break;
        case DemoState.energySaving:
          if (_currentIndex != 0)
            _navigateToPage(0); // Dashboard to show energy drop
          break;
        case DemoState.sustainabilityScore:
          if (_currentIndex != 4) _navigateToPage(4); // Sustainability Score
          break;
        case DemoState.completion:
          if (_currentIndex != 0) _navigateToPage(0); // Back to dashboard for completion
          break;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital EcoHome Demo'),
        backgroundColor: isDarkMode 
            ? AppTheme.darkPrimaryColor 
            : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Demo step counter
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Step ${demoMode.currentStep + 1}/${demoMode.totalSteps}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Reset demo button
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Reset Demo',
            onPressed: () => demoMode.resetDemo(),
          ),
          
          // Exit demo button
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Exit Demo',
            onPressed: () {
              _showExitDemoDialog(context, demoMode);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content with smooth transitions
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _pages[_currentIndex],
            ),
          ),          // Enhanced demo guide overlay
          Positioned(
            bottom: 80, // Position above the demo control panel
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Icon(
                            demoMode.currentScenario.icon,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            demoMode.currentScenario.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _showExitDemoDialog(context, demoMode),
                          tooltip: 'Skip Tour',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      demoMode.currentScenario.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.blueGrey.shade800
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode 
                              ? Colors.blueGrey.shade700
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: isDarkMode 
                                ? Colors.amber.shade300
                                : Colors.amber.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              demoMode.currentScenario.hint,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: isDarkMode
                                    ? Colors.blue.shade100
                                    : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Progress indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Step ${demoMode.currentStep + 1} of ${demoMode.totalSteps}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),

                        // Navigation buttons
                        Row(
                          children: [
                            // Previous button (hidden on first step)
                            if (demoMode.currentStep > 0)
                              TextButton.icon(
                                onPressed: () => demoMode.previousStep(),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Previous'),
                              ),
                            const SizedBox(width: 8),
                            // Next or Finish button
                            ElevatedButton.icon(
                              onPressed: () => demoMode.nextStep(),
                              icon: Icon(
                                demoMode.currentStep == demoMode.totalSteps - 1 
                                    ? Icons.check 
                                    : Icons.arrow_forward,
                              ),
                              label: Text(
                                demoMode.currentStep == demoMode.totalSteps - 1 
                                    ? 'Finish' 
                                    : 'Next'
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),      bottomNavigationBar: DemoControlPanel(
        currentStep: demoMode.currentStep,
        totalSteps: demoMode.totalSteps,
        onReset: () => demoMode.resetDemo(),
        onExit: () => _showExitDemoDialog(context, demoMode),
        onNext: () => demoMode.nextStep(),
        onPrevious: () => demoMode.previousStep(),
      ),
    );
  }
  void _showExitDemoDialog(BuildContext context, DemoMode demoMode) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app,
              color: isDarkMode ? Colors.amber : Colors.orange,
            ),
            const SizedBox(width: 12),
            const Text('Exit Demo Mode?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to exit the demonstration?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your normal app data will be restored, and any changes made during the demo will be discarded.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.blueGrey.shade800
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode 
                      ? Colors.blueGrey.shade700
                      : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can restart the demo at any time from the Settings menu.',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CONTINUE DEMO'),
          ),
          ElevatedButton(
            onPressed: () {
              demoMode.endDemo();
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to main app
              
              // Show a snackbar confirming demo exit
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demo mode exited. Normal app data restored.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.amber : Colors.orange,
              foregroundColor: Colors.black87,
            ),
            child: const Text('EXIT DEMO'),
          ),
        ],
      ),
    );
  }
}
