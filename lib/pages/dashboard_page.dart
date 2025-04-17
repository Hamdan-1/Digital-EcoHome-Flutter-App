import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/data_status.dart'; // Import DataStatus
import '../theme.dart';
import '../widgets/usage_chart.dart';
import '../widgets/notification_badge.dart';
import '../widgets/notification_panel.dart';
import '../services/notification_service.dart';
import '../utils/notification_helper.dart';
// import '../utils/error_handler.dart'; // Unused import
import '../widgets/optimized_loading_indicator.dart';
// Removed Demo Mode imports
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize sample notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSampleNotifications();
    });
  }

  void _initializeSampleNotifications() {
    final notificationService = Provider.of<InAppNotificationService>(
      context,
      listen: false,
    );
    // Use the notification helper to add sample notifications
    NotificationHelper.addSampleNotifications(notificationService);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              title: Row(
                children: [
                  Text(
                    'Digital ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getPrimaryColor(context),
                    ),
                  ),
                  Text(
                    'EcoHome',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
              actions: [
                // Demo Mode Activation Button Removed
                NotificationBadge(
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                    onPressed: () {
                      _showNotificationPanel(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Welcome Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Home',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor and control your home\'s energy usage',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Energy Overview Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // KeyedSubtree removed
                child: _buildEnergyOverviewCard(appState),
              ),
            ),

            // Quick Device Status Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Device Access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            appState.ecoMode ? Icons.eco : Icons.eco_outlined,
                            color:
                                appState.ecoMode
                                    ? Colors.green
                                    : AppTheme.getSecondaryColor(context),
                          ),
                          tooltip:
                              appState.ecoMode
                                  ? 'Eco Mode On'
                                  : 'Enable Eco Mode',
                          onPressed: () {
                            appState.toggleEcoMode();
                          },
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: AppTheme.getSecondaryColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick Device Status List with enhanced animation
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140, // Keep height for layout consistency
                child: _buildDeviceStatusSection(
                  context,
                  appState,
                ), // Use new wrapper method
              ),
            ),

            // Energy Insights Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Energy Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Energy Tip of the Day Card
                    // KeyedSubtree removed
                    _buildEnergyTipCard(appState),

                    const SizedBox(height: 16),

                    // Usage Comparison Card
                    // KeyedSubtree removed
                    _buildUsageComparisonCard(appState),

                    const SizedBox(height: 16),

                    // Notifications Alert Area
                    _buildAlertsList(appState),
                  ],
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyOverviewCard(AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors:
                isDarkMode
                    ? [
                      const Color(0xFF2E7D32),
                      const Color(0xFF1B5E20),
                    ] // Darker green gradient for dark mode
                    : [
                      const Color(0xFF4CAF50),
                      const Color(0xFF2E7D32),
                    ], // Original gradient for light mode
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Power Usage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    // Use a theme-aware color with good contrast on the gradient
                    color: AppTheme.darkTextPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: AppTheme.darkTextPrimaryColor,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 14, // Increased size for better readability
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Enhanced animated Current Power Usage Value with smoother transition
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: appState.currentPowerUsage * 0.95,
                end: appState.currentPowerUsage,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkTextPrimaryColor,
                        shadows:
                            isDarkMode
                                ? [
                                  Shadow(
                                    color: Colors.black.withAlpha(
                                      (0.3 * 255).round(),
                                    ),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ]
                                : [],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        ' kW',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.darkTextPrimaryColor.withAlpha(
                            (0.9 * 255).round(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Improved responsive 24 Hour Usage Chart
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              height: 80,
              child: UsageChart(
                data: appState.hourlyUsageData,
                maxHeight: 80,
                lineColor: AppTheme.darkTextPrimaryColor,
                gradientStartColor: AppTheme.darkTextPrimaryColor.withAlpha(
                  (0.5 * 255).round(),
                ),
                gradientEndColor: AppTheme.darkTextPrimaryColor.withAlpha(
                  (0.0 * 255).round(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Time labels for chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '24h ago',
                  style: TextStyle(
                    fontSize: 14, // Increased size
                    color: AppTheme.darkTextPrimaryColor.withAlpha(
                      (isDarkMode ? 0.9 : 0.7 * 255).round(),
                    ),
                  ),
                ),
                Text(
                  '12h ago',
                  style: TextStyle(
                    fontSize: 14, // Increased size
                    color: AppTheme.darkTextPrimaryColor.withAlpha(
                      (isDarkMode ? 0.9 : 0.7 * 255).round(),
                    ),
                  ),
                ),
                Text(
                  'Now',
                  style: TextStyle(
                    fontSize: 14, // Increased size
                    color: AppTheme.darkTextPrimaryColor.withAlpha(
                      (isDarkMode ? 0.9 : 0.7 * 255).round(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Daily Cost Estimate with enhanced visual feedback
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.black.withAlpha((0.3 * 255).round())
                        : Colors.white.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: AppTheme.darkTextPrimaryColor,
                        size: 20,
                        shadows:
                            isDarkMode
                                ? [
                                  Shadow(
                                    color: Colors.black.withAlpha(
                                      (0.5 * 255).round(),
                                    ),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                                : [],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated Daily Cost',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextPrimaryColor,
                          shadows:
                              isDarkMode
                                  ? [
                                    Shadow(
                                      color: Colors.black.withAlpha(
                                        (0.5 * 255).round(),
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                  : [],
                        ),
                      ),
                    ],
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: appState.calculateDailyCost() * 0.98,
                      end: appState.calculateDailyCost(),
                    ),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Text(
                        '\$${value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextPrimaryColor,
                          shadows:
                              isDarkMode
                                  ? [
                                    Shadow(
                                      color: Colors.black.withAlpha(
                                        (0.5 * 255).round(),
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                  : [],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wrapper method to handle device list status for the horizontal list
  Widget _buildDeviceStatusSection(BuildContext context, AppState appState) {
    switch (appState.devicesStatus) {
      case DataStatus.initial:
      case DataStatus.loading:
        // Show a compact loading indicator suitable for the horizontal space
        return const Center(child: OptimizedLoadingIndicator(size: 24));
      case DataStatus.error:
        // Show a compact error message
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              appState.devicesError ?? 'Could not load devices',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case DataStatus.empty:
        // Show an empty state message for the horizontal list
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'No devices added yet.',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case DataStatus.success:
        // If successful and data is available, build the list
        return _buildDeviceStatusList(context, appState);
    }
  }

  // Builds the actual horizontal list view when data is available
  Widget _buildDeviceStatusList(BuildContext context, AppState appState) {
    // Take only the first 5 devices for the quick access list
    final quickAccessDevices = appState.devices.take(5).toList();

    if (quickAccessDevices.isEmpty) {
      // This case should technically be covered by DataStatus.empty,
      // but added as a safeguard or if filtering logic changes.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'No devices to display.',
            style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: quickAccessDevices.length,
      itemBuilder: (context, index) {
        final device = quickAccessDevices[index];
        // Pass context to the card builder if needed for theming inside it
        return _buildDeviceStatusCard(context, device, appState);
      },
    );
  }

  Widget _buildDeviceStatusCard(
    BuildContext context,
    Device device,
    AppState appState,
  ) {
    final primaryColor = AppTheme.getPrimaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
          },
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _getIconForDevice(device.iconPath),
                            color:
                                device.isActive
                                    ? primaryColor
                                    : AppTheme.getTextSecondaryColor(context),
                            size: device.isActive ? 26 : 24,
                          ),
                        ),
                        if (device.ecoMode)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Icon(
                              Icons.eco,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    Switch(
                      value: device.isActive,
                      onChanged: (_) {
                        HapticFeedback.selectionClick();
                        appState.toggleDevice(device.id);
                      },
                      activeColor: primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  device.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Animated usage value for smoother transitions
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: device.isActive ? device.currentUsage * 0.9 : 0,
                    end: device.isActive ? device.currentUsage : 0,
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      device.isActive ? '${value.toStringAsFixed(0)} W' : 'Off',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            device.isActive
                                // Use a color with better contrast for active state, e.g., secondary text color
                                ? AppTheme.getTextSecondaryColor(context)
                                : AppTheme.getTextSecondaryColor(context),
                        fontWeight:
                            device.isActive
                                ? FontWeight.bold
                                : FontWeight
                                    .normal, // Keep bold only when active
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyTipCard(AppState appState) {
    final tip = appState.currentTip;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getPrimaryColor(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: AppTheme.getSecondaryColor(context),
                ), // Use theme color
                const SizedBox(width: 8),
                Text(
                  'Energy Tip of the Day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? primaryColor.withAlpha((0.15 * 255).round())
                            : primaryColor.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tip.icon, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageComparisonCard(AppState appState) {
    final isLower = appState.isUsageLowerThanYesterday();
    final percentDiff = appState.usageDifferencePercent().toStringAsFixed(1);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? (isLower
                            ? AppTheme.getSuccessColor(context).withAlpha(
                              (0.3 * 255).round(),
                            ) // Use theme color
                            : AppTheme.getErrorColor(
                              context,
                            ).withAlpha((0.3 * 255).round())) // Use theme color
                        : (isLower
                            ? AppTheme.getSuccessColor(context).withAlpha(
                              (0.1 * 255).round(),
                            ) // Use theme color
                            : AppTheme.getErrorColor(context).withAlpha(
                              (0.1 * 255).round(),
                            )), // Use theme color
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLower ? Icons.trending_down : Icons.trending_up,
                color:
                    isLower
                        ? AppTheme.getSuccessColor(context)
                        : AppTheme.getErrorColor(context), // Use theme colors
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLower
                        ? 'Using Less Energy Today'
                        : 'Using More Energy Today',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$percentDiff% ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isLower
                                    ? AppTheme.getSuccessColor(context)
                                    : AppTheme.getErrorColor(
                                      context,
                                    ), // Use theme colors
                          ),
                        ),
                        TextSpan(
                          text:
                              isLower
                                  ? 'less than yesterday'
                                  : 'more than yesterday',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(AppState appState) {
    final alerts = appState.energyAlerts;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show a user-friendly message if there are no alerts
    if (alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'No alerts right now. Looking good!',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications,
              color: AppTheme.getSecondaryColor(context),
            ), // Use theme color
            const SizedBox(width: 8),
            Text(
              'Alerts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: math.min(3, alerts.length),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color:
                  isDarkMode
                      ? (alert.isRead
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha((0.5 * 255).round()) // Use theme color
                          : Theme.of(
                            context,
                          ).colorScheme.errorContainer.withAlpha(
                            (0.4 * 255).round(),
                          )) // Use theme color (e.g., error container for unread)
                      : (alert.isRead
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest // Use theme color
                          : AppTheme.getSecondaryColor(context).withAlpha(
                            (0.1 * 255).round(),
                          )), // Use theme color (e.g., secondary accent for unread)
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        alert.isRead ? FontWeight.normal : FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                subtitle: Text(
                  _formatAlertTime(alert.time),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                trailing:
                    alert.isRead
                        ? null
                        : IconButton(
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.getSecondaryColor(
                              context,
                            ), // Use theme color consistently
                          ),
                          onPressed: () => appState.markAlertAsRead(index),
                        ),
                onTap: () {
                  if (!alert.isRead) {
                    appState.markAlertAsRead(index);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatAlertTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
  }

  IconData _getIconForDevice(String iconPath) {
    switch (iconPath) {
      case 'lightbulb':
        return Icons.lightbulb;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'hot_tub':
        return Icons.hot_tub;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      default:
        return Icons.device_unknown;
    }
  }

  // Method to show notification panel
  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface
                            .withAlpha((0.3 * 255).round()), // Use theme color
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: NotificationPanel(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
