import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart'; // Assuming this service exists and has showNotification
// import '../theme.dart'; // Unused import
import '../widgets/optimized_loading_indicator.dart';

// --- Top-Level Definitions ---

/// Enum representing error severity levels
enum ErrorSeverity { low, medium, high, critical }

/// Notification types for in-app alerts
enum NotificationType { info, success, warning, error }

/// Action for notifications
class NotificationAction {
  final String label;
  final VoidCallback onPressed;

  const NotificationAction({required this.label, required this.onPressed});
}

/// Extension for semantic colors on ColorScheme.
/// Define these colors properly within your AppTheme or main theme data.
extension CustomColorScheme on ColorScheme {
  // Example implementations - replace with your actual theme colors
  Color get warning => brightness == Brightness.light ? Colors.orange.shade700 : Colors.orangeAccent.shade100;
  Color get info => brightness == Brightness.light ? Colors.blue.shade700 : Colors.lightBlueAccent.shade100;
}

// --- ErrorHandler Class ---

/// Class to handle errors throughout the application
class ErrorHandler {

  /// Display a user-friendly error message via notification or fallback SnackBar.
  static void handleError(
    BuildContext context, {
    required String message,
    String? technicalDetails,
    ErrorSeverity severity = ErrorSeverity.medium,
    VoidCallback? onRetry, // Keep onRetry for the fallback SnackBar
    bool showNotification = true,
  }) {
    // Log the error
    debugPrint(
      'ErrorHandler: $message ${technicalDetails != null ? '($technicalDetails)' : ''}',
    );

    if (showNotification) {
      try {
        final notificationService = Provider.of<InAppNotificationService>(context, listen: false);

        // Map ErrorHandler severity/type to InAppNotificationService parameters
        final NotificationPriority priority = _getNotificationPriority(severity);
        final IconData icon = _getNotificationIcon(severity);

        // Call the correct method 'addNotification' from notification_service.dart
        notificationService.addNotification(
          title: _getErrorTitle(severity), // Use existing helper for title
          message: message,
          priority: priority,
          icon: icon,
          // Note: 'duration' and 'action' are not supported by addNotification
          // They are handled by the fallback SnackBar mechanism if needed.
        );
      } catch (e, stackTrace) {
        // Log provider or notification error
        debugPrint('ErrorHandler: Failed to add notification via service: $e\n$stackTrace');
        // Fallback to SnackBar if the notification service fails or isn't found
        _showFallbackError(context, message, severity, onRetry);
      }
    }
  }

  /// Builds a widget to display an error message, optionally with technical details and a retry button.
  static Widget buildErrorDisplay({
    required BuildContext context, // Require context for theming
    required String message,
    String? technicalDetails,
    VoidCallback? onRetry,
    Widget? icon,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    // Delegate to the internal stateful widget
    return _ErrorDisplayWidget(
      message: message,
      technicalDetails: technicalDetails,
      onRetry: onRetry,
      icon: icon,
      severity: severity,
    );
  }

  /// Widget to handle loading, errors, and empty states for asynchronous data.
  static Widget buildAsyncContentHandler<T>({
    required BuildContext context, // Require context for theming defaults
    required AsyncSnapshot<T> snapshot,
    required Widget Function(BuildContext context, T data) builder, // Pass context to builder
    Widget? loadingWidget,
    String loadingMessage = 'Loading...',
    String errorMessage = 'Oops! Something went wrong.',
    String emptyMessage = 'Nothing to show here yet.',
    Widget Function(BuildContext context)? emptyStateBuilder, // Pass context
    VoidCallback? onRetry,
    // Function to check if data should be considered empty (e.g., empty list)
    bool Function(T? data)? isDataEmpty,
  }) {
    final theme = Theme.of(context);

    // Handle loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const OptimizedLoadingIndicator(size: 30),
                  const SizedBox(height: 16),
                  Text(loadingMessage, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          );
    }

    // Handle error state
    if (snapshot.hasError) {
      // Log the specific error and stack trace for debugging
      debugPrint("ErrorHandler Async Error: ${snapshot.error}\n${snapshot.stackTrace}");
      return buildErrorDisplay(
        context: context, // Pass context
        message: errorMessage,
        technicalDetails: snapshot.error?.toString(),
        onRetry: onRetry,
        severity: ErrorSeverity.high, // Default severity for async errors
      );
    }

    // Check for empty data using the provided checker or default checks
    // Added common check for empty lists.
    final bool dataIsEmpty = isDataEmpty?.call(snapshot.data) ??
                             (!snapshot.hasData || snapshot.data == null || (snapshot.data is List && (snapshot.data as List).isEmpty));

    if (dataIsEmpty) {
      // Use custom empty state builder if provided
      if (emptyStateBuilder != null) {
        return emptyStateBuilder(context); // Pass context
      } else {
        // Build improved default empty state
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined, // Standard empty icon
                  size: 60,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nothing Here Yet', // Clearer title
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage, // Use the provided or default message
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                  textAlign: TextAlign.center,
                ),
                 if (onRetry != null) ...[ // Allow retry even on empty state if needed
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: onRetry,
                     icon: const Icon(Icons.refresh),
                     label: const Text('Refresh'),
                     // Style can be customized if needed
                   ),
                 ],
              ],
            ),
          ),
        );
      }
    }

    // Data is available and not empty, build the content
    // Pass context to the builder function
    return builder(context, snapshot.requireData);
  }

  // --- Private Helper Methods ---

  static String _getErrorTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low: return 'Notice';
      case ErrorSeverity.medium: return 'Warning';
      case ErrorSeverity.high: return 'Error';
      case ErrorSeverity.critical: return 'Critical Error';
    }
  }

  // Removed unused method _getNotificationType
  // Removed extra closing brace that broke the class definition

  // Helper to map ErrorSeverity to InAppNotificationService's NotificationPriority
  static NotificationPriority _getNotificationPriority(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low: return NotificationPriority.low;
      case ErrorSeverity.medium: return NotificationPriority.normal;
      case ErrorSeverity.high:
      case ErrorSeverity.critical: return NotificationPriority.high;
    }
  }

  // Helper to get an icon based on severity for addNotification
  static IconData _getNotificationIcon(ErrorSeverity severity) {
     switch (severity) {
      case ErrorSeverity.low: return Icons.info_outline_rounded;
      case ErrorSeverity.medium: return Icons.warning_amber_rounded;
      case ErrorSeverity.high: return Icons.error_outline_rounded;
      case ErrorSeverity.critical: return Icons.dangerous_rounded; // Differentiate critical
    }
  }

  static Duration _getNotificationDuration(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low: return const Duration(seconds: 3);
      case ErrorSeverity.medium: return const Duration(seconds: 5);
      case ErrorSeverity.high: return const Duration(seconds: 7);
      case ErrorSeverity.critical: return const Duration(seconds: 10);
    }
  }

  /// Shows a fallback SnackBar error message.
  static void _showFallbackError(
    BuildContext context,
    String message,
    ErrorSeverity severity,
    VoidCallback? onRetry,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    IconData icon;

    // Determine background color and icon based on severity using theme colors
    switch (severity) {
      case ErrorSeverity.low:
        backgroundColor = colorScheme.info;
        icon = Icons.info_outline;
        break;
      case ErrorSeverity.medium:
        backgroundColor = colorScheme.warning;
        icon = Icons.warning_amber_rounded; // Use rounded version
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        backgroundColor = colorScheme.error;
        icon = Icons.error_outline_rounded; // Use rounded version
        break;
    }

    // Ensure good text contrast
    final textColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black87; // Use slightly off-black for light backgrounds

    // Ensure ScaffoldMessenger is available
    if (ScaffoldMessenger.maybeOf(context) == null) {
       debugPrint("ErrorHandler: Cannot show SnackBar - No ScaffoldMessenger found.");
       return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20), // Slightly smaller icon
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: textColor))),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: _getNotificationDuration(severity),
        behavior: SnackBarBehavior.floating, // Floating looks modern
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(10.0), // Add margin for floating
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: textColor, // Use contrasting text color
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
} // End of ErrorHandler class

// --- Internal Widget for Error Display ---

/// Internal StatefulWidget used by `ErrorHandler.buildErrorDisplay`
/// to manage the collapsible technical details section.
class _ErrorDisplayWidget extends StatefulWidget {
  final String message;
  final String? technicalDetails;
  final VoidCallback? onRetry;
  final Widget? icon;
  final ErrorSeverity severity;

  const _ErrorDisplayWidget({
    required this.message,
    this.technicalDetails,
    this.onRetry,
    this.icon,
    required this.severity,
  });

  @override
  State<_ErrorDisplayWidget> createState() => _ErrorDisplayWidgetState();
}

class _ErrorDisplayWidgetState extends State<_ErrorDisplayWidget> {
  bool _showDetails = false;

  IconData _getDefaultIcon() {
    switch (widget.severity) {
      case ErrorSeverity.low: return Icons.info_outline_rounded;
      case ErrorSeverity.medium: return Icons.warning_amber_rounded;
      case ErrorSeverity.high:
      case ErrorSeverity.critical: return Icons.error_outline_rounded;
    }
  }

  Color _getIconColor(BuildContext context) {
     final theme = Theme.of(context);
     // Use theme colors for icons
     switch (widget.severity) {
      case ErrorSeverity.low: return theme.colorScheme.info;
      case ErrorSeverity.medium: return theme.colorScheme.warning;
      case ErrorSeverity.high:
      case ErrorSeverity.critical: return theme.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _getIconColor(context);
    final bool hasTechDetails = widget.technicalDetails != null && widget.technicalDetails!.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.icon ??
                Icon(
                  _getDefaultIcon(),
                  size: 50, // Slightly smaller icon
                  color: iconColor,
                ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), // Slightly less bold
            ),
            if (hasTechDetails) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showDetails ? 'Hide Details' : 'Show Details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showDetails ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher( // Animate the details section
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SizeTransition(sizeFactor: animation, child: child);
                },
                child: _showDetails
                  ? Padding(
                      key: const ValueKey('details_visible'), // Key for animation
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 150), // Limit height
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()), // Lighter background
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withAlpha((0.2 * 255).round())) // More subtle border
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Text(
                              widget.technicalDetails!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4), // Improve line height
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('details_hidden')), // Use SizedBox.shrink when hidden
              ),
            ],
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                // Use default theme styling for consistency
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Note: The InAppNotificationServiceExtension is removed as it's likely
// handled by the actual service implementation. If needed, define it based
// on the 'notification_service.dart' file structure.
