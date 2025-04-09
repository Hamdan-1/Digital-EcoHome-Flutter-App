import 'package:flutter/material.dart';
import '../models/demo_mode.dart';
import '../theme.dart';
import 'targeted_tooltip.dart';

/// An enhanced guide overlay for demo mode with interactive tooltips
class EnhancedDemoGuide extends StatefulWidget {
  final DemoScenario scenario;
  final int currentStep;
  final int totalSteps;
  final DemoState currentState;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  const EnhancedDemoGuide({
    Key? key,
    required this.scenario,
    required this.currentStep,
    required this.totalSteps,
    required this.currentState,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<EnhancedDemoGuide> createState() => _EnhancedDemoGuideState();
}

class _EnhancedDemoGuideState extends State<EnhancedDemoGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Keys for targeted elements in different scenarios
  final Map<DemoState, GlobalKey> _primaryTargetKeys = {};
  
  // Control whether to show targeted tooltip
  bool _showTooltip = false;
  String _tooltipMessage = '';
  GlobalKey? _activeTooltipTargetKey;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Initialize keys
    for (final state in DemoState.values) {
      _primaryTargetKeys[state] = GlobalKey();
    }

    _animationController.forward();
    
    // Schedule tooltip to appear after card is animated in
    Future.delayed(const Duration(milliseconds: 1000), () {
      _checkAndShowTooltip();
    });
  }

  @override
  void didUpdateWidget(EnhancedDemoGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep || 
        oldWidget.currentState != widget.currentState) {
      _animationController.reset();
      _animationController.forward();
      
      // Hide any active tooltip
      setState(() {
        _showTooltip = false;
      });
      
      // Show new tooltip after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        _checkAndShowTooltip();
      });
    }
  }

  void _checkAndShowTooltip() {
    // Only show tooltips for specific states
    String? message;
    GlobalKey? targetKey;
    
    switch (widget.currentState) {
      case DemoState.dashboardOverview:
        message = 'This graph shows your real-time energy usage. Notice how it changes as devices turn on and off.';
        targetKey = _primaryTargetKeys[DemoState.dashboardOverview];
        break;
      case DemoState.energySpike:
        message = 'The system has detected an unusual energy spike! Check the alerts section for more information.';
        targetKey = _primaryTargetKeys[DemoState.energySpike];
        break;
      case DemoState.deviceControl:
        message = 'Try turning these devices on or off to see how they affect your home\'s energy consumption.';
        targetKey = _primaryTargetKeys[DemoState.deviceControl];
        break;
      case DemoState.smartRecommendation:
        message = 'Our AI assistant analyzes your energy usage patterns and provides personalized recommendations.';
        targetKey = _primaryTargetKeys[DemoState.smartRecommendation];
        break;
      case DemoState.sustainabilityScore:
        message = 'Your sustainability score improves as you implement energy-saving practices.';
        targetKey = _primaryTargetKeys[DemoState.sustainabilityScore];
        break;
      default:
        // No tooltip for other states
        break;
    }
    
    if (message != null && targetKey != null && mounted) {
      setState(() {
        _tooltipMessage = message!;
        _activeTooltipTargetKey = targetKey;
        _showTooltip = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = widget.currentStep == 0;
    final isLastStep = widget.currentStep == widget.totalSteps - 1;
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Main guide card
        Positioned(
          bottom: 80, // Position above the demo control panel
          left: 16,
          right: 16,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
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
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                            child: Icon(
                              widget.scenario.icon,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.scenario.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onSkip,
                            tooltip: 'Skip Tour',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.scenario.description,
                        style: theme.textTheme.bodyLarge,
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
                                widget.scenario.hint,
                                style: theme.textTheme.bodyMedium?.copyWith(
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
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),

                          // Navigation buttons
                          Row(
                            children: [
                              // Previous button (hidden on first step)
                              if (!isFirstStep)
                                TextButton.icon(
                                  onPressed: widget.onPrevious,
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Previous'),
                                ),
                              const SizedBox(width: 8),
                              // Next or Finish button
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Hide tooltip when advancing
                                  setState(() {
                                    _showTooltip = false;
                                  });
                                  widget.onNext();
                                },
                                icon: Icon(
                                  isLastStep ? Icons.check : Icons.arrow_forward,
                                ),
                                label: Text(isLastStep ? 'Finish' : 'Next'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
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
          ),
        ),
        
        // Targeted tooltip overlay when active
        if (_showTooltip && _activeTooltipTargetKey != null)
          TargetedTooltip(
            targetKey: _activeTooltipTargetKey!,
            message: _tooltipMessage,
            icon: Icons.info_outline,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            onDismiss: () {
              setState(() {
                _showTooltip = false;
              });
            },
          ),
          
        // Expose target keys to parent
        Offstage(
          offstage: true,
          child: Column(
            children: [
              // Place target keys in strategic positions
              Container(key: _primaryTargetKeys[DemoState.dashboardOverview]),
              Container(key: _primaryTargetKeys[DemoState.energySpike]),
              Container(key: _primaryTargetKeys[DemoState.deviceControl]),
              Container(key: _primaryTargetKeys[DemoState.smartRecommendation]),
              Container(key: _primaryTargetKeys[DemoState.sustainabilityScore]),
            ],
          ),
        ),
      ],
    );
  }
}

/// Class for demo feature highlight
class DemoFeatureHighlight extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Widget child;

  const DemoFeatureHighlight({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The actual widget
        child,
        
        // Highlight overlay (used during demo to draw attention)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
