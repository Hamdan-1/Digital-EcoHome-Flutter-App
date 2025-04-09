// Notification system for energy alerts and device events
import 'dart:async';
import 'dart:math';
// import 'package:flutter/material.dart'; // Unused import
// Using a simpler implementation without external dependencies
import '../app_state.dart';
import 'energy_usage_simulator.dart';
import 'simulation_config.dart';

class NotificationSystem {
  // In-memory notification storage instead of using system notifications
  final List<Map<String, dynamic>> _pendingNotifications =
      []; // Config for simulation
  final SimulationConfig config;

  // Timer for checking notification conditions
  Timer? _notificationTimer;

  // Track sent notifications to avoid duplicates
  Set<String> _sentNotifications = {};

  // Random for simulation
  final Random random;

  // Constructor
  NotificationSystem(this.config) : random = config.random;

  // Initialize the notification system
  Future<void> initialize() async {
    // No external plugin initialization needed in this simplified version
    // print('Notification system initialized'); // Removed print
  }

  // Start monitoring for notifications
  void startMonitoring({
    required List<Device> devices,
    required EnergyUsageSimulator energySimulator,
    required Function(EnergyAlert) onAlertGenerated,
  }) {
    // Cancel any existing timer
    _notificationTimer?.cancel();

    // Start periodic checks for notification conditions
    _notificationTimer = Timer.periodic(
      Duration(minutes: config.notificationCheckIntervalMinutes),
      (_) => _checkForNotificationConditions(
        devices,
        energySimulator,
        onAlertGenerated,
      ),
    );
  }

  // Stop monitoring
  void stopMonitoring() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  // Check for conditions that should trigger notifications
  void _checkForNotificationConditions(
    List<Device> devices,
    EnergyUsageSimulator energySimulator,
    Function(EnergyAlert) onAlertGenerated,
  ) {
    // Check for energy usage anomalies
    final anomalies = energySimulator.detectAnomalies();

    for (final anomaly in anomalies) {
      // Create a unique ID for this anomaly to prevent duplicates
      final anomalyId =
          '${anomaly.type}_${anomaly.timestamp.day}_${anomaly.timestamp.hour}';
      if (!_sentNotifications.contains(anomalyId)) {
        // Create a notification
        _showNotification(
          title: 'Energy Alert',
          body: anomaly.description,
          importance:
              anomaly.severity == AnomalySeverity.high ? 'high' : 'default',
        );

        // Add to sent notifications
        _sentNotifications.add(anomalyId);

        // Create an energy alert for the app state
        final alert = EnergyAlert(
          message: anomaly.description,
          time: anomaly.timestamp,
        );

        // Notify the app state
        onAlertGenerated(alert);
      }
    }

    // Check for long-running devices
    _checkLongRunningDevices(devices, onAlertGenerated);

    // Generate scheduled usage report (e.g., weekly summary)
    _checkForScheduledReports(energySimulator, onAlertGenerated);

    // Clean up old sent notifications (older than 1 day)
    _cleanupOldNotifications();
  }

  // Check for devices that have been running for a long time
  void _checkLongRunningDevices(
    List<Device> devices,
    Function(EnergyAlert) onAlertGenerated,
  ) {
    final now = DateTime.now();

    // Simulate device runtime tracking
    for (final device in devices) {
      if (!device.isActive) continue;

      // Only check high-power devices (AC, heater, etc.)
      if (device.type == 'HVAC' && device.currentUsage > 800) {
        // Simulate that this device has been running for 4+ hours
        // In a real app, you'd track the actual runtime
        if (random.nextDouble() < 0.3) {
          // 30% chance to trigger
          final hours = 4 + random.nextInt(5); // 4-8 hours
          final notificationId = 'long_running_${device.id}_${now.day}';

          if (!_sentNotifications.contains(notificationId)) {
            // Show notification
            _showNotification(
              title: 'Device Alert',
              body:
                  '${device.name} in ${device.room} has been running for $hours hours',
            );

            // Add to sent notifications
            _sentNotifications.add(notificationId);

            // Create an energy alert
            final alert = EnergyAlert(
              message:
                  '${device.name} in ${device.room} has been running for $hours hours',
              time: now,
            );

            // Notify the app state
            onAlertGenerated(alert);
          }
        }
      }
    }
  }

  // Check if it's time for scheduled energy reports
  void _checkForScheduledReports(
    EnergyUsageSimulator energySimulator,
    Function(EnergyAlert) onAlertGenerated,
  ) {
    final now = DateTime.now();

    // Weekly report on Sunday at 9 AM
    if (now.weekday == DateTime.sunday &&
        now.hour == 9 &&
        now.minute < config.notificationCheckIntervalMinutes) {
      final weeklyUsage = energySimulator.getWeeklyUsage();
      final notificationId = 'weekly_report_${now.day}${now.month}';

      if (!_sentNotifications.contains(notificationId)) {
        // Show notification
        _showNotification(
          title: 'Weekly Energy Report',
          body:
              'Your energy usage this week was ${weeklyUsage.toStringAsFixed(1)} kWh. Tap to view details.',
        );

        // Add to sent notifications
        _sentNotifications.add(notificationId);

        // Create an energy alert that's not an "alert" but an info message
        final alert = EnergyAlert(
          message:
              'Weekly Report: Your energy usage was ${weeklyUsage.toStringAsFixed(1)} kWh',
          time: now,
        );

        // Notify the app state
        onAlertGenerated(alert);
      }
    }

    // Monthly report on 1st of month at 10 AM
    if (now.day == 1 &&
        now.hour == 10 &&
        now.minute < config.notificationCheckIntervalMinutes) {
      final monthlyUsage = energySimulator.getMonthlyUsage();
      final notificationId = 'monthly_report_${now.month}${now.year}';

      if (!_sentNotifications.contains(notificationId)) {
        // Show notification
        _showNotification(
          title: 'Monthly Energy Report',
          body:
              'Your energy usage last month was ${monthlyUsage.toStringAsFixed(1)} kWh. Tap to view details.',
        );

        // Add to sent notifications
        _sentNotifications.add(notificationId);

        // Create an energy alert
        final alert = EnergyAlert(
          message:
              'Monthly Report: Your energy usage was ${monthlyUsage.toStringAsFixed(1)} kWh',
          time: now,
        );

        // Notify the app state
        onAlertGenerated(alert);
      }
    }
  }

  // Show a notification (simulated)
  Future<void> _showNotification({
    required String title,
    required String body,
    String importance = 'default',
  }) async {
    // Instead of showing system notifications, we'll just store them for the app to display
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'title': title,
      'body': body,
      'importance': importance,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _pendingNotifications.add(notification);

    // Log notification for debugging
    // print('NOTIFICATION: $title - $body'); // Removed print
  }

  // Clean up old notifications from the tracking set
  void _cleanupOldNotifications() {
    // final now = DateTime.now(); // Unused variable
    // final yesterday = now.subtract(const Duration(days: 1)); // Unused variable

    // For this simulation, we'll just clear all but the most recent notifications
    // In a real app, you'd want to be more precise with timestamps
    if (_sentNotifications.length > 20) {
      // Keep only the 10 most recent ones (assuming they're added in chronological order)
      // In a real app, you'd actually store timestamps with each notification ID
      _sentNotifications =
          _sentNotifications.skip(_sentNotifications.length - 10).toSet();
    }
  }
}
