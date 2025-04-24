import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/data_status.dart'; // Import DataStatus enum
import '../services/arduino_service.dart'; // Import Arduino Service
import '../theme.dart';
import 'device_control/ac_control_page.dart';
import 'device_control/washing_machine_control_page.dart';
import 'device_control/light_control_page.dart';
import 'device_control/water_heater_control_page.dart';
import 'device_control/refrigerator_control_page.dart';
import '../widgets/optimized_loading_indicator.dart';
import '../utils/error_handler.dart';
// Removed Demo Mode import

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage>
    with SingleTickerProviderStateMixin {
  final List<String> _categories = [
    'All',
    'Lights',
    'HVAC',
    'Appliances',
    'Water',
  ];
  String _selectedCategory = 'All';
  String _selectedRoom = 'All Rooms';
  // bool _isDiscovering = false; // Removed unused field
  AnimationController? _scanAnimationController;
  Animation<double>? _scanAnimation;

  // State for Search and Sort
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  String _sortOption = 'usage_desc'; // Default sort: usage descending

  // State for Arduino Control
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _lcdController = TextEditingController();
  double _windowServoValue = 0; // 0-180
  bool _isDoorLocked = true; // Assuming default is locked
  bool _isFanOn = false;
  double _fanSpeedValue = 150; // 0-255, default moderate speed
  bool _isYellowLedOn = false;
  bool _isWhiteLedOn = false;


  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scanAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Listener for search query changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _scanAnimationController?.dispose();
    _searchController.dispose();
    _ipController.dispose();
    _lcdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get base list of devices
    List<Device> devices = List<Device>.from(appState.devices);

    // Apply sorting (will be refined later)
    devices.sort((a, b) {
      switch (_sortOption) {
        case 'name_asc':
          return a.name.compareTo(b.name);
        case 'name_desc':
          return b.name.compareTo(a.name);
        case 'room_asc':
          return a.room.compareTo(b.room);
        case 'room_desc':
          return b.room.compareTo(a.room);
        case 'usage_asc':
          return a.currentUsage.compareTo(b.currentUsage);
        case 'usage_desc':
        default:
          return b.currentUsage.compareTo(a.currentUsage);
      }
    });

    // Get unique rooms for filtering
    final rooms = ['All Rooms', ...appState.getRooms()];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              title:
                  _isSearchActive
                      ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search devices...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                        ),
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(context),
                          fontSize: 18,
                        ),
                      )
                      : Text(
                        'My Devices',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
              actions: [
                IconButton(
                  icon: Icon(
                    appState.ecoMode ? Icons.eco : Icons.eco_outlined,
                    color:
                        appState.ecoMode
                            ? Colors.green
                            : AppTheme.getSecondaryColor(context),
                  ),
                  tooltip: appState.ecoMode ? 'Eco Mode On' : 'Enable Eco Mode',
                  onPressed: () {
                    appState.toggleEcoMode();
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isSearchActive ? Icons.close : Icons.search,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                  tooltip: _isSearchActive ? 'Close Search' : 'Search Devices',
                  onPressed: () {
                    setState(() {
                      _isSearchActive = !_isSearchActive;
                      if (!_isSearchActive) {
                        _searchController.clear();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.sort,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                  tooltip: 'Sort Devices',
                  onPressed: () => _showSortOptions(context),
                ),
              ],
            ),

            // --- Arduino Control Section ---
            _buildArduinoControlSection(context),
            // --- End Arduino Control Section ---


            // Discovery Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Builder(
                  builder: (context) {
                    // Determine if the discovered section is visible
                    final bool showDiscoveredSection =
                        appState.discoveryStatus != DataStatus.initial ||
                        appState.discoveredDevices.isNotEmpty;
                    final bool isScanning =
                        appState.discoveryStatus == DataStatus.loading;
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          isScanning
                              ? null
                              : () => _handleDeviceDiscovery(appState),
                      icon:
                          (!showDiscoveredSection && isScanning)
                              ? OptimizedLoadingIndicator(
                                size: 20,
                                color: isDarkMode ? Colors.white : Colors.white,
                              )
                              : const Icon(Icons.wifi_find_outlined),
                      label: Text(
                        isScanning ? 'Scanning...' : 'Scan for Devices',
                      ),
                    );
                  },
                ),
              ),
            ),

            // Room filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  0,
                ), // Reduced top padding slightly
                child: Row(
                  children: [
                    Text(
                      'Room:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedRoom,
                        isExpanded: true,
                        dropdownColor: AppTheme.getCardColor(context),
                        underline: Container(
                          height: 1,
                          color: AppTheme.getPrimaryColor(
                            context,
                          ).withAlpha((0.5 * 255).round()),
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRoom = newValue;
                            });
                          }
                        },
                        items:
                            rooms.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color: AppTheme.getTextPrimaryColor(
                                      context,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: 4.0,
                ), // Adjusted vertical padding
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: AppTheme.getPrimaryColor(
                            context,
                          ).withAlpha((0.2 * 255).round()),
                          checkmarkColor: AppTheme.getPrimaryColor(
                            context,
                          ), // Ensure theme usage
                          backgroundColor:
                              isSelected
                                  ? AppTheme.getPrimaryColor(context).withAlpha(
                                    (0.1 * 255).round(),
                                  ) // Use primary color slightly for selected background
                                  : Theme.of(
                                        context,
                                      ).chipTheme.backgroundColor ??
                                      (isDarkMode
                                          ? AppTheme.darkCardColor.withAlpha(
                                            (0.6 * 255).round(),
                                          ) // Fallback
                                          : Colors.grey.withAlpha(
                                            (0.1 * 255).round(),
                                          )),
                          labelStyle:
                              Theme.of(context).chipTheme.labelStyle?.copyWith(
                                // Use theme chip style
                                color:
                                    isSelected
                                        ? AppTheme.getPrimaryColor(context)
                                        : AppTheme.getTextSecondaryColor(
                                          context,
                                        ),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ) ??
                              TextStyle(
                                // Fallback style
                                color:
                                    isSelected
                                        ? AppTheme.getPrimaryColor(context)
                                        : AppTheme.getTextSecondaryColor(
                                          context,
                                        ),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                          side:
                              isSelected // Add border to selected chip
                                  ? BorderSide(
                                    color: AppTheme.getPrimaryColor(
                                      context,
                                    ).withAlpha((0.5 * 255).round()),
                                    width: 1,
                                  )
                                  : Theme.of(context).chipTheme.side ??
                                      BorderSide
                                          .none, // Use theme default or none
                        ),
                      );
                    },
                  ),
                ),
              ),
            ), // Coming Soon Features Section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rocket_launch_outlined, // Use outlined version
                          size: 22,
                          color: AppTheme.getSecondaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.getSecondaryColor(
                              context,
                            ).withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.getSecondaryColor(
                                context,
                              ).withAlpha((0.3 * 255).round()),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            // Removed const
                            'Beta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getSecondaryColor(context),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            // Future feature - Show all upcoming features
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 170,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildComingSoonFeatureCard(
                          context,
                          'Smart Thermostat',
                          Icons.thermostat_outlined,
                          'Intelligent heating and cooling control',
                          'May 2025',
                        ),
                        _buildComingSoonFeatureCard(
                          context,
                          'Security System',
                          Icons.security_outlined,
                          'Home security with motion detection',
                          'June 2025',
                        ),
                        _buildComingSoonFeatureCard(
                          context,
                          'Smart Kitchen',
                          Icons.kitchen_outlined,
                          'Connected appliances and monitoring',
                          'July 2025',
                        ),
                        _buildComingSoonFeatureCard(
                          context,
                          'Water Management',
                          Icons.water_drop_outlined,
                          'Track and optimize water usage',
                          'August 2025',
                        ),
                        _buildComingSoonFeatureCard(
                          context,
                          'Energy Storage',
                          Icons.battery_charging_full_outlined,
                          'Store excess energy for later use',
                          'September 2025',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 24,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ],
              ),
            ),

            // Discovered devices section (when loading, has error, or devices found)
            if (appState.discoveryStatus == DataStatus.loading ||
                appState.discoveryStatus == DataStatus.error ||
                (appState.discoveryStatus == DataStatus.success &&
                    appState.discoveredDevices.isNotEmpty) ||
                appState.discoveryStatus ==
                    DataStatus.empty) // Show section even if empty after scan
              _buildDiscoveredDevicesSection(appState, context),

            // Devices List - Handle Loading/Error/Empty States
            _buildDeviceListSection(context, appState, devices),

            const SliverPadding(
              padding: EdgeInsets.only(bottom: 80),
            ), // Padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleDeviceDiscovery(appState), // Trigger scan
        backgroundColor: AppTheme.getPrimaryColor(context),
        tooltip: 'Scan for New Devices',
        child: const Icon(Icons.add_circle_outline), // Updated Icon
      ),
    );
  } // End of build method

  // --- Helper Methods ---

  Widget _buildDiscoveredDevicesSection(
    AppState appState,
    BuildContext context,
  ) {
    final bool showSection =
        appState.discoveryStatus != DataStatus.initial ||
        appState.discoveredDevices.isNotEmpty;

    // Don't show the section at all if it's initial and no devices were ever discovered
    if (!showSection) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        // Add padding around the whole section
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          // Use Column as the main layout element
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Nearby Devices', // Changed title slightly
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (appState.discoveryStatus == DataStatus.loading)
                    OptimizedLoadingIndicator(
                      size: 18,
                      color: AppTheme.getPrimaryColor(context),
                    ),
                  const Spacer(),
                  if (appState.discoveredDevices.isNotEmpty &&
                      appState.discoveryStatus != DataStatus.loading)
                    TextButton.icon(
                      // Use icon button for Add All
                      onPressed: () {
                        // Basic feedback: Show snackbar, actual progress needs more state
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Adding all devices...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        final discovered = List<Device>.from(
                          appState.discoveredDevices,
                        );
                        for (var device in discovered) {
                          appState.addDiscoveredDevice(device.id);
                        }
                        // Force a rebuild slightly later to reflect changes if AppState notifies quickly
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () => setState(() {}),
                        );
                      },
                      icon: const Icon(Icons.playlist_add_check, size: 20),
                      label: const Text('Add All'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                ],
              ),
            ),
            // Content Area (Scanning Animation, Error, Empty, or List)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Consistent horizontal padding
              child: _buildDiscoveryContent(appState, context),
            ),

            // Divider only if there were discovered devices or error/empty state shown
            if (appState.discoveryStatus != DataStatus.loading &&
                appState.discoveryStatus != DataStatus.initial)
              const Divider(
                height: 24,
                indent: 16,
                endIndent: 16,
              ), // Add indent
          ],
        ),
      ),
    );
  }

  // Helper to build the content area of the discovery section based on status
  Widget _buildDiscoveryContent(AppState appState, BuildContext context) {
    switch (appState.discoveryStatus) {
      case DataStatus.loading:
        return _buildScanningAnimation(appState);

      case DataStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32), // More padding
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  appState.discoveryError ??
                      'An unknown error occurred during scan.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  // Add Retry Button
                  onPressed: () => appState.scanForDevices(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry Scan'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withAlpha((0.8 * 255).round()),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        );

      case DataStatus.empty:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.signal_wifi_off_outlined,
                  size: 40,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'No new devices found nearby.',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case DataStatus.success:
        if (appState.discoveredDevices.isEmpty) {
          // This case might occur if devices were added immediately after discovery
          // Or if the status is success but the list somehow became empty.
          // Show a subtle message or nothing.
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "All discovered devices added.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }
        // Display the list of discovered devices
        return Padding(
          padding: const EdgeInsets.only(bottom: 16), // Padding below list
          child: SizedBox(
            height: 130, // Keep height or adjust as needed
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // Remove horizontal padding here as it's handled by the parent Padding
              itemCount: appState.discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = appState.discoveredDevices[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildDiscoveredDeviceCard(device, appState),
                );
              },
            ),
          ),
        );

      case DataStatus.initial:
        // default: // Case is unreachable as all enum values are handled
        // Don't show anything specific in the initial state before first scan
        return const SizedBox.shrink();
    }
  }

  Widget _buildScanningAnimation(AppState appState) {
    // Add some vertical padding for spacing when shown
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scanAnimationController!,
              builder: (context, child) {
                // Use opacity animation on the rings for a pulsing effect
                final double opacityValue =
                    (0.5 + (_scanAnimation!.value * 0.5)); // 0.5 to 1.0
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base static ring
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.getPrimaryColor(
                            context,
                          ).withAlpha((0.2 * 255).round()),
                          width: 2,
                        ),
                      ),
                    ),
                    // Pulsing rings
                    ...List.generate(3, (i) {
                      final double scaleValue =
                          (_scanAnimation!.value + i / 3) % 1;
                      return Transform.scale(
                        scale: 1 + scaleValue * 0.8,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.getPrimaryColor(
                                context,
                              ).withAlpha(
                                (opacityValue * (1 - scaleValue) * 0.5 * 255)
                                    .round(), // Calculate opacity, then convert to alpha
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Central Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.getPrimaryColor(
                          context,
                        ).withAlpha((0.15 * 255).round()),
                      ),
                      child: Icon(
                        Icons.wifi_find_rounded, // Use rounded version
                        color: AppTheme.getPrimaryColor(context),
                        size: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for nearby devices...', // Slightly different text
              style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredDeviceCard(Device device, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16), // Slightly larger radius
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha((0.5 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          // Use theme's shadow if defined, otherwise keep this subtle one
          // Example: elevation: Theme.of(context).cardTheme.elevation ?? 1,
          // shadowColor: Theme.of(context).shadowColor,
          if (!isDarkMode)
            BoxShadow(
              color: Theme.of(context).shadowColor.withAlpha(
                (0.08 * 255).round(),
              ), // Slightly darker shadow
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 8.0,
        ), // More vertical padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForDevice(device.iconPath),
              color: AppTheme.getPrimaryColor(context), // Use theme getter
              size: 30, // Slightly larger icon
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                device.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.getTextPrimaryColor(
                    context,
                  ), // Use theme getter
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              device.room,
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(
                  context,
                ), // Use theme getter
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 28, // Slightly taller button
              child: ElevatedButton.icon(
                // Use icon button
                onPressed: () => appState.addDiscoveredDevice(device.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryColor(
                    context,
                  ).withAlpha((0.15 * 255).round()), // Lighter background
                  foregroundColor: AppTheme.getPrimaryColor(
                    context,
                  ), // Primary color text/icon
                  elevation: 0, // No elevation
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // Adjust padding
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    // Match card radius
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16), // Add icon
                label: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeviceDiscovery(AppState appState) {
    // Start the animation controller if it's not already running
    if (!_scanAnimationController!.isAnimating) {
      _scanAnimationController!.repeat(reverse: true);
    }

    // Start the device scanning process
    appState.scanForDevices();
  }

  bool _matchesCategory(String deviceType, String category) {
    if (category == 'All') return true;

    switch (category) {
      case 'Lights':
        return deviceType == 'Light';
      case 'HVAC':
        return deviceType == 'HVAC';
      case 'Appliances':
        return deviceType == 'Appliance';
      case 'Water':
        return deviceType == 'Water';
      default:
        return false;
    }
  }

  // Builds the main device list section, handling different states
  Widget _buildDeviceListSection(
    BuildContext context,
    AppState appState,
    List<Device> devices,
  ) {
    switch (appState.devicesStatus) {
      case DataStatus.initial:
      case DataStatus.loading:
        return const SliverFillRemaining(
          // Use SliverFillRemaining to center content
          child: Center(child: OptimizedLoadingIndicator()),
        );
      case DataStatus.error:
        return SliverFillRemaining(
          child: ErrorHandler.buildErrorDisplay(
            context: context,
            message: appState.devicesError ?? 'Failed to load devices.',
            // Optionally add a retry callback if AppState provides a way to reload devices
            // onRetry: () => appState.reloadDevices(), // Example
          ),
        );
      case DataStatus.empty:
        return SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 60,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Devices Found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the '+' button below to add your first smart device.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      case DataStatus.success:
        // Filter devices based on search, room, and category *before* building the list
        final filteredDevices =
            devices.where((device) {
              // Search filter (case-insensitive)
              final searchLower = _searchQuery.toLowerCase();
              final nameMatch = device.name.toLowerCase().contains(searchLower);
              final roomNameMatch = device.room.toLowerCase().contains(
                searchLower,
              );
              final searchMatch =
                  _searchQuery.isEmpty || nameMatch || roomNameMatch;

              // Room filter
              final roomMatch =
                  _selectedRoom == 'All Rooms' || device.room == _selectedRoom;

              // Category filter
              final categoryMatch =
                  _selectedCategory == 'All' ||
                  _matchesCategory(device.type, _selectedCategory);

              return searchMatch && roomMatch && categoryMatch;
            }).toList();

        if (filteredDevices.isEmpty) {
          // Show empty state specific to filters/search
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  // Use column for icon + text
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_off_outlined,
                      size: 40,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No devices match the selected filters.'
                          : 'No devices found for "$_searchQuery".',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Build the list with filtered devices
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final device = filteredDevices[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _buildDeviceListItem(context, device, appState),
            );
          }, childCount: filteredDevices.length),
        );
    }
  }

  Widget _buildDeviceListItem(
    BuildContext context,
    Device device,
    AppState appState,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEco = device.ecoMode;

    return Stack(
      children: [
        if (isEco)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withAlpha((0.18 * 255).round()),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Card(
          elevation:
              isEco
                  ? 6
                  : (isDarkMode
                      ? 1
                      : (Theme.of(context).cardTheme.elevation ?? 2)),
          color:
              Theme.of(context).cardTheme.color ??
              (isDarkMode ? AppTheme.darkCardColor : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:
                isEco
                    ? BorderSide(color: Colors.green.withAlpha((0.5 * 255).round()), width: 2)
                    : BorderSide(
                      color: Theme.of(context).dividerColor.withAlpha(
                        (isDarkMode ? 0.5 : 0.2 * 255).round(),
                      ),
                      width: 1,
                    ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            leading: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        device.isActive
                            ? AppTheme.getPrimaryColor(
                              context,
                            ).withAlpha((isDarkMode ? 0.3 : 0.15 * 255).round())
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withAlpha((0.5 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForDevice(device.iconPath),
                    color:
                        device.isActive
                            ? AppTheme.getPrimaryColor(context)
                            : Theme.of(context).disabledColor,
                    size: 28,
                  ),
                ),
                if (isEco)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withAlpha((0.3 * 255).round()),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.eco, color: Colors.green, size: 18),
                    ),
                  ),
              ],
            ),
            title: Text(
              device.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.room,
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            device.isActive
                                ? AppTheme.getSuccessColor(context)
                                : Theme.of(
                                  context,
                                ).disabledColor.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.isActive ? 'Online' : 'Offline',
                      style: TextStyle(
                        color:
                            device.isActive
                                ? AppTheme.getSuccessColor(context)
                                : Theme.of(
                                  context,
                                ).disabledColor.withAlpha((0.9 * 255).round()),
                        fontSize: 12,
                        fontWeight:
                            device.isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 14,
                      color:
                          device.isActive
                              ? AppTheme.getPrimaryColor(context)
                              : Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.isActive
                          ? '${device.currentUsage.toStringAsFixed(0)} W'
                          : 'Inactive',
                      style: TextStyle(
                        color:
                            device.isActive
                                ? AppTheme.getPrimaryColor(context)
                                : Theme.of(context).disabledColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildDeviceSpecificSubtitleInfo(context, device),
                  ],
                ),
                if (device.isActive && device.maxUsage > 0) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: (device.currentUsage / device.maxUsage).clamp(
                        0.0,
                        1.0,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).dividerColor.withAlpha((0.3 * 255).round()),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.getPrimaryColor(
                          context,
                        ).withAlpha((0.8 * 255).round()),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Switch(
              value: device.isActive,
              onChanged: (_) => appState.toggleDevice(device.id),
              activeColor: AppTheme.getPrimaryColor(context),
            ),
            onTap: () {
              _navigateToDeviceControl(context, device);
            },
          ),
        ),
      ],
    );
  }  void _navigateToDeviceControl(BuildContext context, Device device) {
    Widget controlPage;

    if (device.type == 'HVAC') {
      controlPage = ACControlPage(deviceId: device.id);
    } else if (device.type == 'Appliance' &&
        device.iconPath == 'local_laundry_service') {
      controlPage = WashingMachineControlPage(deviceId: device.id);
    } else if (device.type == 'Light') {
      controlPage = LightControlPage(deviceId: device.id);
    } else if (device.type == 'Appliance' &&
        device.iconPath == 'kitchen') {
      controlPage = RefrigeratorControlPage(deviceId: device.id);
    } else if ((device.type == 'Appliance' || device.type == 'Water') &&
        (device.iconPath == 'hot_tub' || device.name.toLowerCase().contains('water heater'))) {
      controlPage = WaterHeaterControlPage(deviceId: device.id);
    } else {
      // Show a toast that control page is not implemented for this device type
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Control page for ${device.name} is not available yet'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => controlPage),
    );
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

  // Helper widget to display device-specific info in the subtitle
  Widget _buildDeviceSpecificSubtitleInfo(BuildContext context, Device device) {
    if (!device.isActive || device.settings == null) {
      return const SizedBox.shrink(); // Return empty if inactive or no settings
    }

    List<Widget> infoWidgets = [];
    final secondaryColor = AppTheme.getTextSecondaryColor(context);
    final textStyle = TextStyle(color: secondaryColor, fontSize: 12);

    // HVAC Temperature
    if (device.type == 'HVAC' && device.settings!['temperature'] != null) {
      final temp = device.settings!['temperature'];
      // Assuming AppState has formatting helpers (add if needed)
      // final formattedTemp = Provider.of<AppState>(context, listen: false).formatTemperature(temp.toDouble());
      final formattedTemp = '$temp°C'; // Simple formatting for now
      infoWidgets.addAll([
        Icon(Icons.thermostat_outlined, size: 14, color: secondaryColor),
        const SizedBox(width: 4),
        Text(formattedTemp, style: textStyle),
      ]);
    }
    // Light Brightness
    else if (device.type == 'Light' && device.settings!['brightness'] != null) {
      final brightness = device.settings!['brightness'];
      infoWidgets.addAll([
        Icon(Icons.brightness_6_outlined, size: 14, color: secondaryColor),
        const SizedBox(width: 4),
        Text('$brightness%', style: textStyle),
      ]);
    }
    // Washing Machine Status (Example)
    else if (device.type == 'Appliance' &&
        device.iconPath == 'local_laundry_service' &&
        device.settings!['isRunning'] == true) {
      final remaining = device.settings!['remainingMinutes'] ?? 0;
      infoWidgets.addAll([
        Icon(Icons.timelapse, size: 14, color: secondaryColor),
        const SizedBox(width: 4),
        Text('$remaining min', style: textStyle),
      ]);
    }

    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use a Row for the specific info elements
    return Row(mainAxisSize: MainAxisSize.min, children: infoWidgets);
  }

  Widget _buildComingSoonFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    String releaseDate,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getPrimaryColor(context);

    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withAlpha((isDarkMode ? 0.8 : 1.0 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha((0.5 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Theme.of(context).shadowColor.withAlpha(
                (0.08 * 255).round(),
              ), // Match discovered card shadow
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Show feature details when tapped
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title coming in $releaseDate'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            splashColor: primaryColor.withAlpha((0.1 * 255).round()),
            highlightColor: primaryColor.withAlpha((0.05 * 255).round()),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: primaryColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.getTextPrimaryColor(
                                  context,
                                ), // Use theme getter
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.getTextSecondaryColor(
                                  context,
                                ), // Use theme getter
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withAlpha((0.2 * 255).round()),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppTheme.getTextSecondaryColor(
                              context,
                            ), // Use theme getter
                          ),
                          const SizedBox(width: 4),
                          Text(
                            releaseDate,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.getTextSecondaryColor(
                                context,
                              ), // Use theme getter
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
  } // End of _buildComingSoonFeatureCard method

  // --- Sorting Logic ---

  void _showSortOptions(BuildContext context) {
    final Map<String, String> sortOptions = {
      'usage_desc': 'Usage: High to Low',
      'usage_asc': 'Usage: Low to High',
      'name_asc': 'Name: A to Z',
      'name_desc': 'Name: Z to A',
      'room_asc': 'Room: A to Z',
      'room_desc': 'Room: Z to A',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor, // Use theme card color
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Sort Devices By',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ...sortOptions.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                final isSelected = _sortOption == key;

                return ListTile(
                  title: Text(
                    value,
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppTheme.getPrimaryColor(context)
                              : AppTheme.getTextPrimaryColor(context),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked, // Corrected icon name
                    color:
                        isSelected
                            ? AppTheme.getPrimaryColor(context)
                            : AppTheme.getTextSecondaryColor(context),
                    size: 22,
                  ),
                  onTap: () {
                    setState(() {
                      _sortOption = key;
                    });
                    Navigator.pop(context); // Close the bottom sheet
                  },
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 0,
                  ),
                );
              }), // .toList() is unnecessary here
              const SizedBox(height: 8), // Bottom padding
            ],
          ),
        );
      },
    );
  }


  // --- Arduino Control Section Widget ---

  Widget _buildArduinoControlSection(BuildContext context) {
  // Use Consumer to listen to ArduinoService changes
  return SliverToBoxAdapter(
    child: Consumer<ArduinoService>(
      builder: (context, arduinoService, child) {
        final isConnected = arduinoService.isConnected;
        final sensorData = arduinoService.sensorData;
        final hasError = arduinoService.hasError;
        final errorMessage = arduinoService.errorMessage;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        // Reset local UI state if disconnected
        // This prevents showing incorrect states after disconnection
        if (!isConnected && (_isFanOn || !_isDoorLocked || _windowServoValue != 0 || _isYellowLedOn || _isWhiteLedOn)) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) { // Ensure widget is still mounted before calling setState
                setState(() {
                  _windowServoValue = 0;
                  _isDoorLocked = true; // Assuming default is locked
                  _isFanOn = false;
                  _fanSpeedValue = 150; // Reset speed too
                  _isYellowLedOn = false;
                  _isWhiteLedOn = false;
                  _lcdController.clear(); // Clear LCD input
                });
             }
           });
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isDarkMode ? 2 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isConnected
                  ? Colors.green.withAlpha(150)
                  : Theme.of(context).dividerColor.withAlpha(100),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Connection Row ---
                Row(
                  children: [
                    Icon(
                      Icons.wifi_tethering,
                      color: isConnected
                          ? Colors.green
                          : AppTheme.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Arduino Control',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // --- IP Input and Connect/Disconnect ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'Arduino IP Address',
                          hintText: 'e.g., 192.168.1.100',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        enabled: !isConnected, // Disable if connected
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (isConnected) {
                          arduinoService.disconnect();
                        } else {
                          if (_ipController.text.isNotEmpty) {
                            // Basic validation could be added here
                            arduinoService.connect(_ipController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter the Arduino IP address')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? Colors.redAccent : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Add space before potential error

                // --- Display Error Message ---
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withAlpha(150),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage ?? 'An unknown error occurred.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Divider(height: 24),

                // --- Controls (Enabled only if connected) ---
                AbsorbPointer(
                  absorbing: !isConnected, // Disable interactions if not connected
                  child: Opacity(
                    opacity: isConnected ? 1.0 : 0.5, // Dim if not connected
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- LCD Control ---
                        Text('LCD Display:', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _lcdController,
                                decoration: InputDecoration(
                                  hintText: 'Text to display...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send),
                              tooltip: 'Send to LCD',
                              onPressed: () {
                                arduinoService.updateLcd(_lcdController.text);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.getPrimaryColor(context).withAlpha(50),
                                foregroundColor: AppTheme.getPrimaryColor(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- Window Servo ---
                        Text('Window Control (0-180): ${(_windowServoValue).round()}', style: Theme.of(context).textTheme.titleMedium),
                        Slider(
                          value: _windowServoValue,
                          min: 0,
                          max: 180,
                          divisions: 18,
                          label: _windowServoValue.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _windowServoValue = value;
                            });
                          },
                          onChangeEnd: (double value) { // Send command when slider interaction ends
                             arduinoService.setWindowAngle(value);
                          },
                        ),
                        const SizedBox(height: 8),

                        // --- Door Servo ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text('Door Control:', style: Theme.of(context).textTheme.titleMedium),
                             ElevatedButton.icon(
                                onPressed: () {
                                  bool newState = !_isDoorLocked;
                                  arduinoService.setDoor(!newState); // Send command to lock/unlock
                                  setState(() {
                                    _isDoorLocked = newState; // Update UI state optimistically
                                  });
                                },
                                icon: Icon(_isDoorLocked ? Icons.lock_outline : Icons.lock_open_outlined),
                                label: Text(_isDoorLocked ? 'Unlock Door' : 'Lock Door'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDoorLocked ? Colors.orangeAccent : Colors.lightBlueAccent,
                                  foregroundColor: Colors.white,
                                ),
                             )
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- Fan Control ---
                        Text('Fan Control:', style: Theme.of(context).textTheme.titleMedium),
                        Row(
                          children: [
                            const Text('Off / On'),
                            Switch(
                              value: _isFanOn,
                              onChanged: (bool value) {
                                arduinoService.setFan(value);
                                setState(() {
                                  _isFanOn = value;
                                });
                              },
                              activeColor: AppTheme.getPrimaryColor(context),
                            ),
                            Expanded(child: Container()), // Spacer
                            Text('Speed: ${(_fanSpeedValue).round()}'),
                          ],
                        ),
                        Slider(
                          value: _fanSpeedValue,
                          min: 0,
                          max: 255,
                          divisions: 25, // Optional divisions
                          label: _fanSpeedValue.round().toString(),
                          onChanged: _isFanOn ? (double value) { // Only allow change if fan is ON
                            setState(() {
                              _fanSpeedValue = value;
                            });
                          } : null, // Disable slider if fan is off
                          onChangeEnd: (double value) {
                            if (_isFanOn) { // Only send if fan is on
                               arduinoService.setFanSpeed(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // --- LED Control ---
                        Text('LED Control:', style: Theme.of(context).textTheme.titleMedium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Yellow LED'),
                                Switch(
                                  value: _isYellowLedOn,
                                  onChanged: (bool value) {
                                    arduinoService.setLed('YELLOW', value);
                                    setState(() { _isYellowLedOn = value; });
                                  },
                                  activeColor: Colors.amber,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('White LED'),
                                Switch(
                                  value: _isWhiteLedOn,
                                  onChanged: (bool value) {
                                     arduinoService.setLed('WHITE', value);
                                     setState(() { _isWhiteLedOn = value; });
                                  },
                                  activeColor: Colors.blueGrey[100],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- Buzzer Control ---
                        Text('Buzzer Control:', style: Theme.of(context).textTheme.titleMedium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => arduinoService.triggerBuzzer('ON'),
                              child: const Text('Beep'),
                            ),
                            ElevatedButton(
                              onPressed: () => arduinoService.triggerBuzzer('ALARM'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('Alarm'),
                            ),
                             ElevatedButton(
                              onPressed: () => arduinoService.triggerBuzzer('OFF'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                              child: const Text('Off'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),

                // --- Sensor Readings ---
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Sensor Readings:', style: Theme.of(context).textTheme.titleMedium),
                     IconButton(
                       icon: const Icon(Icons.refresh),
                       tooltip: 'Refresh Sensor Data',
                       onPressed: isConnected ? () => arduinoService.requestSensorUpdate() : null,
                     )
                   ],
                ),
                const SizedBox(height: 8),
                if (isConnected)
                  Wrap( // Use Wrap for flexible layout
                    spacing: 12.0, // Horizontal space between items
                    runSpacing: 8.0, // Vertical space between lines
                    // Manually create chips for each sensor from the SensorData object
                    children: [
                      _buildSensorChip(context, 'GAS', sensorData.gas, Icons.gas_meter_outlined),
                      _buildSensorChip(context, 'LIGHT', sensorData.light, Icons.lightbulb_outline),
                      _buildSensorChip(context, 'SOIL', sensorData.soil, Icons.grass),
                      _buildSensorChip(context, 'WATER', sensorData.water, Icons.water_drop_outlined),
                      _buildSensorChip(context, 'PIR', sensorData.pir, Icons.directions_run),
                    ],
                  )
                else
                   Text(
                     'Connect to Arduino to view sensor readings.',
                     style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                   ),
              ],
            ),
          ),
        );
      },
    ),
  );
  }

  // Helper to get icons for sensor keys
  IconData _getSensorIcon(String key) {
    switch (key) {
      case 'GAS': return Icons.gas_meter_outlined;
      case 'LIGHT': return Icons.lightbulb_outline;
      case 'SOIL': return Icons.grass; // Placeholder
      case 'WATER': return Icons.water_drop_outlined;
      case 'PIR': return Icons.directions_run; // Placeholder for motion
      default: return Icons.help_outline;
    }
  }

  // Helper widget to build a sensor chip consistently
  Widget _buildSensorChip(BuildContext context, String label, dynamic value, IconData icon) {
     final primaryColor = AppTheme.getPrimaryColor(context);
     return Chip(
       avatar: Icon(
         icon,
         color: primaryColor,
         size: 18,
       ),
       label: Text(
         '$label: $value', // Display label and value
         style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
       ),
       backgroundColor: primaryColor.withAlpha(30),
       side: BorderSide(color: primaryColor.withAlpha(80)),
       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Adjust padding
     );
   }

} // End of _DevicesPageState class
