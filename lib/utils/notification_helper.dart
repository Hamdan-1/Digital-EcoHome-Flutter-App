import '../services/notification_service.dart';
import 'package:flutter/material.dart';

/// Helper class to initialize sample notifications for demonstration purposes
class NotificationHelper {
  /// Add sample notifications to the notification service
  static void addSampleNotifications(
    InAppNotificationService notificationService,
  ) {
    // Clear any existing notifications
    notificationService.clearNotifications();

    // Add high priority notification - energy usage alert
    notificationService.addNotification(
      title: 'High Energy Consumption Alert',
      message:
          'Your home is using 30% more electricity than usual at this time. Check your HVAC system.',
      priority: NotificationPriority.high,
      icon: Icons.warning_amber_rounded,
    );

    // Add normal priority notification - energy saving tip
    notificationService.addNotification(
      title: 'Energy Saving Opportunity',
      message:
          'Your refrigerator is consuming more energy than normal. Consider checking the door seal and temperature settings.',
      priority: NotificationPriority.normal,
      icon: Icons.eco,
    );

    // Add device notification
    notificationService.addNotification(
      title: 'Device Inactive',
      message:
          'Your Smart Thermostat has been offline for 2 hours. Check your Wi-Fi connection or device power.',
      priority: NotificationPriority.normal,
      icon: Icons.device_unknown,
    );

    // Add utility rate notification
    notificationService.addNotification(
      title: 'Peak Rate Hours',
      message:
          'Utility peak rate hours start in 30 minutes. Consider reducing energy usage from 2-5 PM.',
      priority: NotificationPriority.normal,
      icon: Icons.attach_money,
    );

    // Add achievement notification
    notificationService.addNotification(
      title: 'Energy Goal Achieved',
      message:
          'Congratulations! You\'ve reduced your energy consumption by 15% compared to last month.',
      priority: NotificationPriority.normal,
      icon: Icons.emoji_events,
    );

    // Mark some notifications as read to demonstrate both states
    // Get the list of notifications
    final notifications = notificationService.notifications;
    if (notifications.length >= 3) {
      notificationService.markAsRead(
        notifications[2].id,
      ); // Mark the third notification as read
      if (notifications.length >= 5) {
        notificationService.markAsRead(
          notifications[4].id,
        ); // Mark the fifth notification as read
      }
    }
  }
}
