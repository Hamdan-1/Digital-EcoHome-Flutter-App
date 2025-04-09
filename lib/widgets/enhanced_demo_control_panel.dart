import 'package:flutter/material.dart';
import '../theme.dart';

/// An enhanced control panel for demo mode navigation
class EnhancedDemoControlPanel extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onReset;
  final VoidCallback onExit;
  final bool allowAutoAdvance;
  final Function(bool) onToggleAutoAdvance;

  const EnhancedDemoControlPanel({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onReset,
    required this.onExit,
    this.allowAutoAdvance = false,
    required this.onToggleAutoAdvance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFirstStep = currentStep == 0;
    final isLastStep = currentStep == totalSteps - 1;
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate progress percentage
    final progress = (currentStep / (totalSteps - 1)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            color: theme.colorScheme.primary,
            minHeight: 4,
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reset button
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                ),
              ),
              
              // Navigation controls
              Row(
                children: [
                  // Previous button
                  IconButton(
                    onPressed: isFirstStep ? null : onPrevious,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: isFirstStep 
                        ? theme.disabledColor
                        : theme.colorScheme.primary,
                    ),
                    tooltip: 'Previous Step',
                  ),
                  
                  // Step indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.primary,
                    ),
                    child: Text(
                      '${currentStep + 1} / $totalSteps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Next button
                  IconButton(
                    onPressed: isLastStep ? null : onNext,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: isLastStep 
                        ? theme.disabledColor
                        : theme.colorScheme.primary,
                    ),
                    tooltip: 'Next Step',
                  ),
                ],
              ),
              
              // Exit button
              TextButton.icon(
                onPressed: onExit,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Exit Demo'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          
          // Auto-advance toggle (if enabled)
          if (allowAutoAdvance)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Auto-advance:'),
                  Switch(
                    value: allowAutoAdvance,
                    onChanged: (value) => onToggleAutoAdvance(value),
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
