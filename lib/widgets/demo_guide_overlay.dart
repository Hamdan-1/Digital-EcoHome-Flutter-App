import 'package:flutter/material.dart';
import '../models/demo_mode.dart';

class DemoGuideOverlay extends StatefulWidget {
  final DemoScenario scenario;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  const DemoGuideOverlay({
    Key? key,
    required this.scenario,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<DemoGuideOverlay> createState() => _DemoGuideOverlayState();
}

class _DemoGuideOverlayState extends State<DemoGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

    _animationController.forward();
  }

  @override
  void didUpdateWidget(DemoGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _animationController.reset();
      _animationController.forward();
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

    return Positioned(
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
                        backgroundColor: theme.primaryColor.withOpacity(0.2),
                        child: Icon(
                          widget.scenario.icon,
                          color: theme.primaryColor,
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
                  Text(
                    widget.scenario.hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress indicator
                      Text(
                        'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
                        style: theme.textTheme.bodySmall,
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
                            onPressed: widget.onNext,
                            icon: Icon(
                              isLastStep ? Icons.check : Icons.arrow_forward,
                            ),
                            label: Text(isLastStep ? 'Finish' : 'Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
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
    );
  }
}
