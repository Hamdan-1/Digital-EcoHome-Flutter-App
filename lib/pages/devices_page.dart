import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import 'device_control/ac_control_page.dart';
import 'device_control/washing_machine_control_page.dart';
import 'device_control/light_control_page.dart';

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
  bool _isDiscovering = false;
  AnimationController? _scanAnimationController;
  Animation<double>? _scanAnimation;

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
  }

  @override
  void dispose() {
    _scanAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Sort devices by power consumption (highest first)
    final devices = List<Device>.from(appState.devices)
      ..sort((a, b) => b.currentUsage.compareTo(a.currentUsage));

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
              title: const Text(
                'My Devices',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: AppTheme.textPrimaryColor,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: AppTheme.textPrimaryColor,
                  ),
                  onPressed: () {},
                ),
              ],
            ),

            // Discovery Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      appState.isScanning
                          ? null
                          : () => _handleDeviceDiscovery(appState),
                  icon:
                      appState.isScanning
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.search),
                  label: Text(
                    appState.isScanning ? 'Scanning...' : 'Scan for Devices',
                  ),
                ),
              ),
            ),

            // Room filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    const Text(
                      'Room:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedRoom,
                        isExpanded: true,
                        underline: Container(
                          height: 1,
                          color: AppTheme.primaryColor.withOpacity(0.5),
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
                                child: Text(value),
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color:
                                _selectedCategory == category
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryColor,
                            fontWeight:
                                _selectedCategory == category
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Coming Soon Features Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Beta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildComingSoonFeatureCard(
                            'Smart Thermostat',
                            'Advanced AI temperature control',
                            Icons.thermostat,
                            Colors.deepPurple,
                          ),
                          _buildComingSoonFeatureCard(
                            'Security System',
                            'Integrated cameras and sensors',
                            Icons.security,
                            Colors.red,
                          ),
                          _buildComingSoonFeatureCard(
                            'Smart Kitchen',
                            'Connected appliances and recipes',
                            Icons.kitchen,
                            Colors.amber,
                          ),
                          _buildComingSoonFeatureCard(
                            'Water Management',
                            'Monitor and optimize water usage',
                            Icons.water_drop,
                            Colors.blue,
                          ),
                          _buildComingSoonFeatureCard(
                            'Energy Storage',
                            'Home battery integration',
                            Icons.battery_charging_full,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                ),
              ),
            ),

            // Discovered devices section (when scanning or devices found)
            if (appState.isScanning || appState.discoveredDevices.isNotEmpty)
              _buildDiscoveredDevicesSection(appState),

            // Devices List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final device = devices[index];

                // Apply room filter
                if (_selectedRoom != 'All Rooms' &&
                    device.room != _selectedRoom) {
                  return null;
                }

                // Apply category filter
                if (_selectedCategory != 'All' &&
                    !_matchesCategory(device.type, _selectedCategory)) {
                  return null;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _buildDeviceListItem(context, device, appState),
                );
              }, childCount: devices.length),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDiscoveredDevicesSection(AppState appState) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Discovered Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                if (appState.isScanning)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                const Spacer(),
                if (appState.discoveredDevices.isNotEmpty &&
                    !appState.isScanning)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // Clear discovered devices
                        for (var device in appState.discoveredDevices) {
                          appState.addDiscoveredDevice(device.id);
                        }
                      });
                    },
                    child: const Text('Add All'),
                  ),
              ],
            ),
          ),
          if (appState.isScanning) _buildScanningAnimation(appState),
          if (!appState.isScanning && appState.discoveredDevices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('No devices found. Try scanning again.'),
            ),
          if (appState.discoveredDevices.isNotEmpty)
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildScanningAnimation(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scanAnimationController!,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    ...List.generate(3, (i) {
                      final double value = (_scanAnimation!.value + i / 3) % 1;
                      return Container(
                        width: 120 * (1 + value * 0.8),
                        height: 120 * (1 + value * 0.8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(
                              0.5 * (1 - value),
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.wifi_find,
                        color: AppTheme.primaryColor,
                        size: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Searching for smart devices...',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredDeviceCard(Device device, AppState appState) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForDevice(device.iconPath),
              color: AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                device.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              device.room,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 24,
              child: ElevatedButton(
                onPressed: () => appState.addDiscoveredDevice(device.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Add'),
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

  Widget _buildDeviceListItem(
    BuildContext context,
    Device device,
    AppState appState,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
                device.isActive
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForDevice(device.iconPath),
            color: device.isActive ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  device.room,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: device.isActive ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  device.isActive ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  size: 14,
                  color: device.isActive ? AppTheme.primaryColor : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  device.isActive
                      ? '${device.currentUsage.toStringAsFixed(0)} W'
                      : 'Inactive',
                  style: TextStyle(
                    color:
                        device.isActive ? AppTheme.primaryColor : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: device.isActive,
          onChanged: (_) => appState.toggleDevice(device.id),
          activeColor: AppTheme.primaryColor,
        ),
        onTap: () {
          _navigateToDeviceControl(context, device);
        },
      ),
    );
  }

  void _navigateToDeviceControl(BuildContext context, Device device) {
    Widget controlPage;

    if (device.type == 'HVAC') {
      controlPage = ACControlPage(deviceId: device.id);
    } else if (device.type == 'Appliance' &&
        device.iconPath == 'local_laundry_service') {
      controlPage = WashingMachineControlPage(deviceId: device.id);
    } else if (device.type == 'Light') {
      controlPage = LightControlPage(deviceId: device.id);
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

  Widget _buildComingSoonFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
