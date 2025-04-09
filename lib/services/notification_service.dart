import 'dart:async';
import 'package:flutter/material.dart';

/// A simple notification model for in-app notifications
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationPriority priority;
  final IconData? icon;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.priority = NotificationPriority.normal,
    this.icon,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? time,
    NotificationPriority? priority,
    IconData? icon,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      icon: icon ?? this.icon,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum NotificationPriority { low, normal, high }

/// Service to manage in-app notifications
class InAppNotificationService extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final _notificationStreamController =
      StreamController<AppNotification>.broadcast();

  // Stream for real-time notification updates
  Stream<AppNotification> get notificationStream =>
      _notificationStreamController.stream;

  // Get all notifications
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Add a new notification
  void addNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    IconData? icon,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      time: DateTime.now(),
      priority: priority,
      icon: icon,
    );

    _notifications.add(notification);
    _notificationStreamController.add(notification);
    notifyListeners();
  }

  // Mark a notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  // Remove a notification by ID
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}
