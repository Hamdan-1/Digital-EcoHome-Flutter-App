import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../theme.dart';

/// Class to handle errors throughout the application
class ErrorHandler {
  /// Display a user-friendly error message with fallback error handling
  static void handleError(
    BuildContext context, {
    required String message,
    String? technicalDetails,
    ErrorSeverity severity = ErrorSeverity.medium,
    VoidCallback? onRetry,
    bool showNotification = true,
  }) {
    // Log the error (would typically send to a logging service in production)
    debugPrint('Error: $message ${technicalDetails != null ? '($technicalDetails)' : ''}');
    
    // Show in-app notification for non-critical errors
    if (showNotification) {
      try {
        final notificationService = Provider.of<InAppNotificationService>(
          context, 
          listen: false,
        );
        
        notificationService.showNotification(
          title: _getErrorTitle(severity),
          message: message,
          type: _getNotificationType(severity),
          duration: _getNotificationDuration(severity),
          action: onRetry != null 
              ? NotificationAction(label: 'Retry', onPressed: onRetry)
              : null,
        );
      } catch (e) {
        // Fallback if the notification service isn't available
        _showFallbackError(context, message, severity, onRetry);
      }
    }
  }
  
  /// Show a fullscreen error when content can't be loaded
  static Widget buildErrorDisplay({
    required String message,
    String? technicalDetails,
    VoidCallback? onRetry,
    Widget? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ?? const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (technicalDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                technicalDetails,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Widget to handle loading, errors, and empty states
  static Widget buildAsyncContentHandler<T>({
    required AsyncSnapshot<T> snapshot,
    required Widget Function(T data) builder,
    Widget? loadingWidget,
    String loadingMessage = 'Loading...',
    String errorMessage = 'Something went wrong',
    String emptyMessage = 'No data available',
    VoidCallback? onRetry,
  }) {
    // Handle loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingWidget ?? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingMessage),
          ],
        ),
      );
    }
    
    // Handle error state
    if (snapshot.hasError) {
      return buildErrorDisplay(
        message: errorMessage,
        technicalDetails: snapshot.error.toString(),
        onRetry: onRetry,
      );
    }
    
    // Handle empty data
    if (!snapshot.hasData || snapshot.data == null) {
      return buildErrorDisplay(
        message: emptyMessage,
        icon: const Icon(
          Icons.inbox,
          size: 60,
          color: Colors.grey,
        ),
        onRetry: onRetry,
      );
    }
    
    // Data is available, build the content
    return builder(snapshot.data as T);
  }
  
  // Helper methods
  static String _getErrorTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 'Notice';
      case ErrorSeverity.medium:
        return 'Warning';
      case ErrorSeverity.high:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }
  
  static NotificationType _getNotificationType(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return NotificationType.info;
      case ErrorSeverity.medium:
        return NotificationType.warning;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        return NotificationType.error;
    }
  }
  
  static Duration _getNotificationDuration(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return const Duration(seconds: 3);
      case ErrorSeverity.medium:
        return const Duration(seconds: 5);
      case ErrorSeverity.high:
        return const Duration(seconds: 7);
      case ErrorSeverity.critical:
        return const Duration(seconds: 10);
    }
  }
  
  static void _showFallbackError(
    BuildContext context,
    String message,
    ErrorSeverity severity,
    VoidCallback? onRetry,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Color backgroundColor;
    Color textColor = isDarkMode ? Colors.white : Colors.white;
    IconData icon;
    
    switch (severity) {
      case ErrorSeverity.low:
        backgroundColor = Colors.blue;
        icon = Icons.info_outline;
        break;
      case ErrorSeverity.medium:
        backgroundColor = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case ErrorSeverity.high:
        backgroundColor = Colors.deepOrange;
        icon = Icons.error_outline;
        break;
      case ErrorSeverity.critical:
        backgroundColor = Colors.red;
        icon = Icons.dangerous;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: _getNotificationDuration(severity),
        action: onRetry != null ? SnackBarAction(
          label: 'RETRY',
          textColor: textColor,
          onPressed: onRetry,
        ) : null,
      ),
    );
  }
}

/// Enum representing error severity levels
enum ErrorSeverity {
  low,
  medium, 
  high,
  critical,
}

/// Extension to add the notification service functionality
/// (Add this if your NotificationService doesn't have these methods yet)
extension InAppNotificationServiceExtension on InAppNotificationService {
  void showNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration? duration,
    NotificationAction? action,
  }) {
    // Implementation depends on your existing notification service
    // This is just a placeholder to handle the API calls above
  }
}

/// Notification types for in-app alerts
enum NotificationType {
  info,
  success,
  warning,
  error,
}

/// Action for notifications
class NotificationAction {
  final String label;
  final VoidCallback onPressed;
  
  const NotificationAction({
    required this.label,
    required this.onPressed,
  });
}
