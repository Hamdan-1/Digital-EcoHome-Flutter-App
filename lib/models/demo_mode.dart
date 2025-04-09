// Demo Mode Model for Digital EcoHome
// Handles guided walkthrough functionality and simulated scenarios

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'simulation/energy_usage_simulator.dart';

enum DemoState {
  introduction,
  dashboardOverview,
  energySpike,
  deviceControl,
  smartRecommendation,
  energySaving,
  sustainabilityScore,
  completion,
}

class DemoScenario {
  final String title;
  final String description;
  final String hint;
  final IconData icon;
  final int durationInSeconds;
  final List<DemoTutorialStep>? tutorialSteps; // Optional step-by-step tutorial
  final String? detailedExplanation; // More detailed content for popups
  final List<String>? keyFeatures; // List of key features to highlight

  DemoScenario({
    required this.title,
    required this.description,
    required this.hint,
    required this.icon,
    required this.durationInSeconds,
    this.tutorialSteps,
    this.detailedExplanation,
    this.keyFeatures,
  });
}

/// A single step in a detailed tutorial sequence
class DemoTutorialStep {
  final String title;
  final String instruction;
  final String targetElementId; // ID of UI element to highlight
  final IconData? icon;

  DemoTutorialStep({
    required this.title,
    required this.instruction,
    required this.targetElementId,
    this.icon,
  });
}

class DemoMode with ChangeNotifier {
  bool _isActive = false;
  DemoState _currentState = DemoState.introduction;
  int _currentStep = 0;
  final Random _random = Random();
  Timer? _scenarioTimer;
  final AppState _appState;
  bool _autoAdvance = false; // Support for auto-advancing through demo
  int _scenarioStartTime =
      0; // Keep track of when scenarios start for timed events

  // Store original app state to restore after demo
  List<Device>? _originalDevices;
  double? _originalTodayUsage;
  double? _originalWeeklyUsage;
  double? _originalMonthlyUsage;
  List<double>? _originalHourlyUsage;
  List<EnergyAlert>? _originalAlerts;

  // Demo-specific values
  List<Device> _demoDevices = [];
  List<double> _demoHourlyUsage = [];
  List<EnergyAlert> _demoAlerts = [];
  // Demo scenarios with enhanced content and interactive tutorials
  final List<DemoScenario> _demoScenarios = [
    // Introduction
    DemoScenario(
      title: 'Welcome to Digital EcoHome Demo',
      description:
          'This guided tour will show you how the app helps monitor and optimize your home\'s energy usage.',
      hint: 'Tap Next to continue or Skip Tour to exit the demo mode.',
      icon: Icons.home,
      durationInSeconds: 0, // Manual advance
      detailedExplanation:
          'Digital EcoHome is your comprehensive solution for home energy management. '
          'This demo will walk you through key features and show you how the app can help '
          'reduce your energy consumption, save money, and make your home more environmentally friendly. '
          '\n\nDuring this demo, you\'ll see simulated data that represents typical home usage patterns, '
          'along with interactive examples of how the system responds to different scenarios.',
      keyFeatures: [
        'Real-time energy monitoring',
        'Smart device control',
        'AI-powered recommendations',
        'Sustainability scoring',
        'Anomaly detection',
      ],
    ),

    // Dashboard Overview
    DemoScenario(
      title: 'Dashboard Overview',
      description:
          'The Dashboard shows your current power consumption, daily usage, and energy trends at a glance.',
      hint:
          'Notice how the real-time usage chart updates as devices turn on and off.',
      icon: Icons.dashboard,
      durationInSeconds: 15,
      detailedExplanation:
          'The Dashboard is your central hub for monitoring energy usage in real-time. '
          'It displays your current power consumption in watts, daily energy usage in kWh, '
          'and shows trends over time through intuitive graphs. '
          '\n\nThe hourly breakdown helps you identify peak usage times, while the alerts section '
          'keeps you informed of unusual patterns or opportunities to save energy.',
      tutorialSteps: [
        DemoTutorialStep(
          title: 'Real-Time Usage',
          instruction:
              'This chart shows your power consumption updating in real-time. The spikes indicate when high-power devices turn on.',
          targetElementId: 'dashboard_usage_chart',
          icon: Icons.show_chart,
        ),
        DemoTutorialStep(
          title: 'Daily Summary',
          instruction:
              'Your daily energy usage is summarized here, with a comparison to your typical consumption.',
          targetElementId: 'dashboard_daily_summary',
          icon: Icons.today,
        ),
        DemoTutorialStep(
          title: 'Alerts & Notifications',
          instruction:
              'Important alerts about unusual usage patterns or energy-saving opportunities appear in this section.',
          targetElementId: 'dashboard_alerts',
          icon: Icons.notifications,
        ),
      ],
    ),

    // Energy Spike Demonstration
    DemoScenario(
      title: 'Energy Spike Detection',
      description:
          'Digital EcoHome detects unusual energy usage patterns and alerts you immediately.',
      hint:
          'Watch as the system detects a sudden increase in energy consumption.',
      icon: Icons.warning_amber,
      durationInSeconds: 20,
      detailedExplanation:
          'The anomaly detection system continuously monitors your energy consumption patterns. '
          'When it detects unusual spikes or unexpected changes in usage, it sends immediate alerts. '
          '\n\nThis feature can help you identify potential problems like: '
          '\n• Appliances that may be malfunctioning '
          '\n• Devices accidentally left on '
          '\n• Unexpected consumption during away periods '
          '\n\nDuring this demonstration, you\'ll see how the system responds to a simulated energy spike.',
    ),

    // Device Control
    DemoScenario(
      title: 'Smart Device Control',
      description:
          'Control all your connected devices and see their energy impact in real-time.',
      hint:
          'Try turning devices on/off to see how they affect your total consumption.',
      icon: Icons.devices,
      durationInSeconds: 25,
      detailedExplanation:
          'The Devices section gives you complete control over all connected smart devices in your home. '
          'You can monitor each device\'s energy consumption, turn devices on or off remotely, and set '
          'automated schedules to optimize energy usage. '
          '\n\nThe system categorizes devices by type and shows which ones are currently active. '
          'For compatible smart devices, you can also adjust specific settings like temperature, '
          'brightness, or operating mode.',
      tutorialSteps: [
        DemoTutorialStep(
          title: 'Device Controls',
          instruction:
              'Tap any device to view detailed information and controls. Try turning a device on/off to see how it affects energy usage.',
          targetElementId: 'device_list',
          icon: Icons.touch_app,
        ),
        DemoTutorialStep(
          title: 'Energy Impact',
          instruction:
              'Each device shows its current power consumption in watts. Notice how higher-power devices have a bigger impact on your total usage.',
          targetElementId: 'device_energy_impact',
          icon: Icons.power,
        ),
      ],
    ),

    // Smart Recommendations
    DemoScenario(
      title: 'AI-Powered Recommendations',
      description:
          'Receive personalized suggestions to optimize your energy usage based on your habits.',
      hint:
          'The system analyzes usage patterns to provide actionable insights.',
      icon: Icons.lightbulb,
      durationInSeconds: 18,
      detailedExplanation:
          'Digital EcoHome\'s AI assistant continuously analyzes your energy usage patterns '
          'to identify opportunities for optimization. The recommendations are personalized to '
          'your specific habits and home setup. '
          '\n\nThese smart suggestions can include: '
          '\n• Optimal times to run high-energy appliances '
          '\n• Device-specific efficiency tips '
          '\n• Behavioral changes that could reduce consumption '
          '\n• Long-term investment suggestions like smart thermostats or LED lighting',
      tutorialSteps: [
        DemoTutorialStep(
          title: 'Smart Recommendations',
          instruction:
              'The AI assistant provides personalized suggestions based on your usage patterns and potential savings.',
          targetElementId: 'recommendations',
          icon: Icons.psychology,
        ),
      ],
    ),

    // Energy Saving Scenario
    DemoScenario(
      title: 'Energy Saving in Action',
      description:
          'See how small changes can lead to significant energy and cost savings over time.',
      hint:
          'Watch your energy consumption drop as smart recommendations are implemented.',
      icon: Icons.trending_down,
      durationInSeconds: 20,
      detailedExplanation:
          'This demonstration shows the real impact of implementing energy-saving recommendations. '
          'By making simple adjustments to device usage and settings, you can see immediate reductions '
          'in power consumption. '
          '\n\nThe system calculates both immediate savings and projected long-term impact: '
          '\n• Daily kWh reduction '
          '\n• Monthly cost savings '
          '\n• Carbon footprint decrease '
          '\n\nThese small changes add up over time to significant financial and environmental benefits.',
    ),

    // Sustainability Score
    DemoScenario(
      title: 'Your Sustainability Score',
      description:
          'Track your environmental impact with a comprehensive sustainability score.',
      hint:
          'The score updates as your energy habits change, encouraging greener choices.',
      icon: Icons.eco,
      durationInSeconds: 15,
      detailedExplanation:
          'The Sustainability Score provides a simple way to track your home\'s environmental impact. '
          'Scores range from 0-100, with higher scores indicating more sustainable energy usage. '
          '\n\nThe score is calculated based on multiple factors: '
          '\n• Overall energy efficiency '
          '\n• Usage during peak/off-peak hours '
          '\n• Adoption of energy-saving features '
          '\n• Consistency of conservation habits '
          '\n\nYour score is compared with neighborhood averages, creating a friendly competition '
          'that encourages continued improvement.',
      tutorialSteps: [
        DemoTutorialStep(
          title: 'Your Score',
          instruction:
              'This gauge shows your current sustainability score. It updates as you implement energy-saving practices.',
          targetElementId: 'sustainability_score',
          icon: Icons.eco,
        ),
        DemoTutorialStep(
          title: 'Improvement Tips',
          instruction:
              'These personalized suggestions help you improve your score and reduce environmental impact.',
          targetElementId: 'energy_saving_tips',
          icon: Icons.lightbulb_outline,
        ),
      ],
    ),

    // Completion
    DemoScenario(
      title: 'Demo Completed',
      description:
          'You\'ve completed the Digital EcoHome guided tour! Ready to start monitoring your real home?',
      hint: 'Exit demo mode to begin using the app with your actual home data.',
      icon: Icons.celebration,
      durationInSeconds: 0, // Manual advance
      detailedExplanation:
          'Congratulations on completing the Digital EcoHome demonstration! '
          '\n\nYou\'ve experienced the key features that make this app a powerful tool for energy management: '
          '\n• Real-time monitoring of energy consumption '
          '\n• Smart device control and automation '
          '\n• AI-powered recommendations '
          '\n• Sustainability tracking and neighborhood comparison '
          '\n• Anomaly detection and alerts '
          '\n\nWhen you exit demo mode, the app will connect to your actual home data and devices. '
          'You can return to this demonstration at any time from the Settings menu.',
    ),
  ];

  DemoMode(this._appState);
  // Getters
  bool get isActive => _isActive;
  DemoState get currentState => _currentState;
  int get currentStep => _currentStep;
  int get totalSteps => _demoScenarios.length;
  DemoScenario get currentScenario => _demoScenarios[_currentStep];
  bool get autoAdvance => _autoAdvance;

  // Setter for auto-advance
  void setAutoAdvance(bool value) {
    _autoAdvance = value;

    // If turning on auto-advance, start the timer if not already running
    if (_autoAdvance) {
      _startAutoAdvanceTimer();
    } else {
      // If turning off auto-advance, cancel the timer
      _scenarioTimer?.cancel();
    }

    notifyListeners();
  }

  // Start the auto-advance timer
  void _startAutoAdvanceTimer() {
    // Cancel any existing timer
    _scenarioTimer?.cancel();

    // Get the current scenario duration
    final duration = _demoScenarios[_currentStep].durationInSeconds;

    // Only start timer if the scenario has a duration
    if (duration > 0) {
      _scenarioTimer = Timer(Duration(seconds: duration), () {
        if (_autoAdvance && _currentStep < _demoScenarios.length - 1) {
          nextStep();
        }
      });
    }
  }

  // Start demo mode
  void startDemo() {
    if (_isActive) return;

    // Store original state
    _backupOriginalState();

    // Set demo flag
    _isActive = true;
    _currentStep = 0;
    _currentState = DemoState.introduction;

    // Initialize demo data
    _initializeDemoData();

    notifyListeners();
  }

  // Backup original app state
  void _backupOriginalState() {
    _originalDevices = List.from(_appState.devices);
    _originalTodayUsage = _appState.todayUsage;
    _originalWeeklyUsage = _appState.weeklyUsage;
    _originalMonthlyUsage = _appState.monthlyUsage;
    _originalHourlyUsage = List.from(_appState.hourlyUsageData);
    _originalAlerts = List.from(_appState.energyAlerts);
  }

  // Initialize demo with sample data
  void _initializeDemoData() {
    // Create demo devices with predefined behavior
    _demoDevices = [
      SmartAC(
        id: 'demo-ac-1',
        name: 'Living Room AC',
        isActive: true,
        currentUsage: 1200.0,
        room: 'Living Room',
      ),
      SmartLight(
        id: 'demo-light-1',
        name: 'Kitchen Lights',
        isActive: true,
        currentUsage: 45.0,
        room: 'Kitchen',
      ),
      SmartLight(
        id: 'demo-light-2',
        name: 'Living Room Lights',
        isActive: true,
        currentUsage: 60.0,
        room: 'Living Room',
      ),
      SmartWashingMachine(
        id: 'demo-washer-1',
        name: 'Washing Machine',
        isActive: false,
        currentUsage: 0.0,
        room: 'Laundry Room',
      ),
      Device(
        id: 'demo-fridge-1',
        name: 'Refrigerator',
        type: 'Appliance',
        isActive: true,
        currentUsage: 120.0,
        iconPath: 'kitchen',
        maxUsage: 200.0,
        room: 'Kitchen',
      ),
      Device(
        id: 'demo-tv-1',
        name: 'Smart TV',
        type: 'Entertainment',
        isActive: false,
        currentUsage: 0.0,
        iconPath: 'tv',
        maxUsage: 150.0,
        room: 'Living Room',
      ),
      Device(
        id: 'demo-water-1',
        name: 'Water Heater',
        type: 'Water',
        isActive: true,
        currentUsage: 750.0,
        iconPath: 'hot_tub',
        maxUsage: 1200.0,
        room: 'Bathroom',
      ),
    ];

    // Initialize hourly data with a realistic baseline pattern
    _initializeDemoHourlyData();

    // Initial alerts
    _demoAlerts = [
      EnergyAlert(
        message: 'Welcome to Digital EcoHome Demo Mode',
        time: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];

    // Apply demo data to app state
    _updateAppStateWithDemoData();
  }

  // Initialize demo hourly data
  void _initializeDemoHourlyData() {
    final now = DateTime.now();
    final currentHour = now.hour;

    _demoHourlyUsage = List.generate(24, (index) {
      // Calculate hour of the day (0-23)
      final hour = (currentHour - 23 + index) % 24;

      // Create a realistic pattern based on time of day
      double baseValue;

      // Night time (low usage)
      if (hour >= 0 && hour < 6) {
        baseValue = 0.8 + (_random.nextDouble() * 0.4);
      }
      // Morning peak
      else if (hour >= 6 && hour < 10) {
        baseValue = 1.8 + (_random.nextDouble() * 0.8);
      }
      // Midday moderate
      else if (hour >= 10 && hour < 17) {
        baseValue = 1.5 + (_random.nextDouble() * 0.6);
      }
      // Evening peak (highest usage)
      else if (hour >= 17 && hour < 22) {
        baseValue = 2.2 + (_random.nextDouble() * 1.0);
      }
      // Late evening (decreasing)
      else {
        baseValue = 1.2 + (_random.nextDouble() * 0.6);
      }

      return baseValue;
    });
  }

  // Update app state with demo data
  void _updateAppStateWithDemoData() {
    // We'll use the ReflectiveInjector pattern to update the app state
    // with our demo data without modifying the original class

    // Using reflection would be ideal here but Flutter doesn't support it well,
    // so we'll expose update methods through the AppState class directly

    // For now, we'll simulate this with a helper method that would need
    // to be added to AppState
    _updateAppStateDemo();
  }

  // Helper method to advance to the next step
  void nextStep() {
    if (_currentStep < _demoScenarios.length - 1) {
      _currentStep++;
      _applyScenarioEffects();
      notifyListeners();
    }
  }

  // Helper method to go to the previous step
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _applyScenarioEffects();
      notifyListeners();
    }
  }

  // Apply effects based on the current scenario
  void _applyScenarioEffects() {
    // Cancel any existing timer
    _scenarioTimer?.cancel();

    // Reset any temporary changes
    _updateAppStateWithDemoData();

    // Apply specific effects based on the current scenario
    switch (_currentStep) {
      case 0: // Introduction
        _currentState = DemoState.introduction;
        break;

      case 1: // Dashboard Overview
        _currentState = DemoState.dashboardOverview;
        _startRegularUpdates();
        break;

      case 2: // Energy Spike
        _currentState = DemoState.energySpike;
        _simulateEnergySpike();
        break;

      case 3: // Device Control
        _currentState = DemoState.deviceControl;
        // No special effects needed
        break;

      case 4: // Smart Recommendations
        _currentState = DemoState.smartRecommendation;
        _simulateRecommendations();
        break;

      case 5: // Energy Saving
        _currentState = DemoState.energySaving;
        _simulateEnergySaving();
        break;

      case 6: // Sustainability Score
        _currentState = DemoState.sustainabilityScore;
        // No special effects needed
        break;

      case 7: // Completion
        _currentState = DemoState.completion;
        break;
    }

    // Start timer for auto-advance if duration is set
    final duration = _demoScenarios[_currentStep].durationInSeconds;
    if (duration > 0) {
      _scenarioTimer = Timer(Duration(seconds: duration), () {
        nextStep();
      });
    }
  }

  // Simulate an energy spike scenario
  void _simulateEnergySpike() {
    // Create a timer sequence to simulate events
    Timer(const Duration(seconds: 2), () {
      // Turn on high energy devices
      final washerIndex = _demoDevices.indexWhere(
        (d) => d.id == 'demo-washer-1',
      );
      if (washerIndex != -1) {
        _demoDevices[washerIndex] = SmartWashingMachine(
          id: 'demo-washer-1',
          name: 'Washing Machine',
          isActive: true, // Turn on
          currentUsage: 650.0,
          room: 'Laundry Room',
        );
      }

      final tvIndex = _demoDevices.indexWhere((d) => d.id == 'demo-tv-1');
      if (tvIndex != -1) {
        _demoDevices[tvIndex] = Device(
          id: 'demo-tv-1',
          name: 'Smart TV',
          type: 'Entertainment',
          isActive: true, // Turn on
          currentUsage: 120.0,
          iconPath: 'tv',
          maxUsage: 150.0,
          room: 'Living Room',
        );
      }

      // Add energy spike in hourly data
      final List<double> updatedHourly = List.from(_demoHourlyUsage);
      updatedHourly[updatedHourly.length - 1] = 4.2; // Significant spike
      _demoHourlyUsage = updatedHourly;

      // Create alert
      _demoAlerts.insert(
        0,
        EnergyAlert(
          message:
              'Unusual energy spike detected! Multiple high-power devices running simultaneously.',
          time: DateTime.now(),
        ),
      );

      _updateAppStateDemo();
      notifyListeners();
    });
  }

  // Simulate smart recommendations
  void _simulateRecommendations() {
    Timer(const Duration(seconds: 3), () {
      // Add recommendation alerts
      _demoAlerts.insert(
        0,
        EnergyAlert(
          message:
              'Recommendation: Washing machine would use 20% less energy if run during off-peak hours (after 9 PM).',
          time: DateTime.now(),
        ),
      );

      Timer(const Duration(seconds: 4), () {
        _demoAlerts.insert(
          0,
          EnergyAlert(
            message:
                'Recommendation: Living Room AC is set 3°F lower than your usual preference. Adjusting could save 15% energy.',
            time: DateTime.now(),
          ),
        );

        _updateAppStateDemo();
        notifyListeners();
      });

      _updateAppStateDemo();
      notifyListeners();
    });
  }

  // Simulate energy saving scenario
  void _simulateEnergySaving() {
    Timer(const Duration(seconds: 2), () {
      // Turn off high-energy devices
      final washerIndex = _demoDevices.indexWhere(
        (d) => d.id == 'demo-washer-1',
      );
      if (washerIndex != -1) {
        _demoDevices[washerIndex] = SmartWashingMachine(
          id: 'demo-washer-1',
          name: 'Washing Machine',
          isActive: false,
          currentUsage: 0.0,
          room: 'Laundry Room',
        );
      }

      // Adjust AC settings
      final acIndex = _demoDevices.indexWhere((d) => d.id == 'demo-ac-1');
      if (acIndex != -1) {
        final ac = _demoDevices[acIndex] as SmartAC;
        final updatedSettings = Map<String, dynamic>.from(ac.settings ?? {});
        updatedSettings['temperature'] = 76; // More energy-efficient setting

        _demoDevices[acIndex] = SmartAC(
          id: 'demo-ac-1',
          name: 'Living Room AC',
          isActive: true,
          currentUsage: 850.0, // Lower usage
          room: 'Living Room',
        );
      }

      // Show the energy usage drop in hourly data
      final List<double> updatedHourly = List.from(_demoHourlyUsage);
      updatedHourly[updatedHourly.length - 1] = 1.8; // Significant drop
      _demoHourlyUsage = updatedHourly;

      // Add success alert
      _demoAlerts.insert(
        0,
        EnergyAlert(
          message:
              'Energy saving mode activated! Current consumption reduced by 30%.',
          time: DateTime.now(),
        ),
      );

      _updateAppStateDemo();
      notifyListeners();
    });
  }

  // Start regular updates for demo
  void _startRegularUpdates() {
    _scenarioTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Add small random variations to device usage
      for (int i = 0; i < _demoDevices.length; i++) {
        if (_demoDevices[i].isActive) {
          final device = _demoDevices[i];

          // Add random fluctuation based on device type
          double fluctuation;
          switch (device.type) {
            case 'HVAC':
              fluctuation = (_random.nextDouble() * 100) - 50;
              break;
            case 'Light':
              fluctuation = (_random.nextDouble() * 5) - 2.5;
              break;
            case 'Appliance':
              fluctuation = (_random.nextDouble() * 20) - 10;
              break;
            default:
              fluctuation = (_random.nextDouble() * 10) - 5;
          }

          // Calculate new usage with fluctuation
          double newUsage = device.currentUsage + fluctuation;

          // Ensure within bounds
          if (newUsage < 0) newUsage = 0;
          if (newUsage > device.maxUsage) newUsage = device.maxUsage;

          // Create updated device (specific to each type)
          if (device is SmartAC) {
            _demoDevices[i] = SmartAC(
              id: device.id,
              name: device.name,
              isActive: device.isActive,
              currentUsage: newUsage,
              room: device.room,
            );
          } else if (device is SmartLight) {
            _demoDevices[i] = SmartLight(
              id: device.id,
              name: device.name,
              isActive: device.isActive,
              currentUsage: newUsage,
              room: device.room,
            );
          } else if (device is SmartWashingMachine) {
            _demoDevices[i] = SmartWashingMachine(
              id: device.id,
              name: device.name,
              isActive: device.isActive,
              currentUsage: newUsage,
              room: device.room,
            );
          } else {
            _demoDevices[i] = Device(
              id: device.id,
              name: device.name,
              type: device.type,
              isActive: device.isActive,
              currentUsage: newUsage,
              iconPath: device.iconPath,
              maxUsage: device.maxUsage,
              room: device.room,
              settings: device.settings,
            );
          }
        }
      }

      _updateAppStateDemo();
      notifyListeners();
    });
  }

  // End demo mode and restore original state
  void endDemo() {
    // Cancel any timers
    _scenarioTimer?.cancel();

    // Restore original data
    _restoreOriginalState();

    // Reset demo flag
    _isActive = false;

    notifyListeners();
  }

  // Reset demo to beginning
  void resetDemo() {
    // Cancel any timers
    _scenarioTimer?.cancel();

    // Reset to initial state
    _currentStep = 0;
    _currentState = DemoState.introduction;

    // Reinitialize demo data
    _initializeDemoData();

    notifyListeners();
  }

  // Restore original app state
  void _restoreOriginalState() {
    if (_originalDevices != null) {
      // Add helper method to AppState to restore original values
      _restoreAppStateOriginal();
    }
  }

  // Temporary methods that would be implemented in AppState
  void _updateAppStateDemo() {
    // In a real implementation, this would update the AppState
    // with our demo data
    notifyListeners();
  }

  void _restoreAppStateOriginal() {
    // In a real implementation, this would restore the original
    // app state
    notifyListeners();
  }

  @override
  void dispose() {
    // Make sure to clean up
    _scenarioTimer?.cancel();
    super.dispose();
  }
}
