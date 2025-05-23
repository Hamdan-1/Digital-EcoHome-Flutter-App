import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/animations.dart'; // Import AnimatedTapButton
import '../services/notification_service.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InAppNotificationService>(
      builder: (context, notificationService, _) {
        final notifications = notificationService.notifications;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, notificationService),
              if (notifications.isEmpty)
                _buildEmptyState(context)
              else
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(
                        context,
                        notification,
                        notificationService,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, InAppNotificationService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notifications',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (service.notifications.isNotEmpty)
            // Wrap TextButton with AnimatedTapButton
            AnimatedTapButton(
              onTap: () => service.clearNotifications(),
              child: TextButton(
                onPressed: null, // Handled by AnimatedTapButton
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, // Remove default padding if needed
                  minimumSize: Size.zero, // Remove default minimum size if needed
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Adjust tap area
                ),
                child: const Text('Clear All'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you receive notifications, they\'ll appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
    InAppNotificationService service,
  ) {
    final formatter = DateFormat('MMM d, h:mm a');
    final formattedTime = formatter.format(notification.time);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => service.removeNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(
            context,
            notification.priority,
          ).withAlpha((0.2 * 255).round()),
          child: Icon(
            notification.icon ?? Icons.notifications,
            color: _getPriorityColor(context, notification.priority),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => service.markAsRead(notification.id),
        tileColor:
            notification.isRead
                ? null
                : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Theme.of(context).colorScheme.error;
      case NotificationPriority.normal:
        return Theme.of(context).colorScheme.primary;
      case NotificationPriority.low:
        return Theme.of(context).colorScheme.secondary;
    }
  }
}
