import 'package:flutter/material.dart';

class DemoControlPanel extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onReset;
  final VoidCallback onExit;

  const DemoControlPanel({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onReset,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstStep = currentStep == 0;
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
            const SizedBox(height: 12),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side buttons
                Row(
                  children: [
                    // Reset button
                    Tooltip(
                      message: 'Reset Demo',
                      child: IconButton(
                        icon: const Icon(Icons.replay),
                        onPressed: onReset,
                        color: theme.colorScheme.secondary,
                      ),
                    ),

                    // Exit button
                    Tooltip(
                      message: 'Exit Demo Mode',
                      child: IconButton(
                        icon: const Icon(Icons.exit_to_app),
                        onPressed: onExit,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),

                // Right side navigation buttons
                Row(
                  children: [
                    // Previous button (disabled on first step)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: isFirstStep ? null : onPrevious,
                      color:
                          isFirstStep
                              ? theme.disabledColor
                              : theme.colorScheme.primary,
                    ),

                    // Step indicator
                    Text(
                      '${currentStep + 1}/$totalSteps',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Next button (finish on last step)
                    IconButton(
                      icon: Icon(
                        isLastStep ? Icons.check_circle : Icons.arrow_forward,
                      ),
                      onPressed: onNext,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
