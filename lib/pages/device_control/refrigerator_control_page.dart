import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/app_state.dart'; // Using the original Device class
import '../../models/data_status.dart';
import '../../theme.dart';
import '../../widgets/optimized_loading_indicator.dart';
import '../../utils/error_handler.dart';

class RefrigeratorControlPage extends StatefulWidget {
  final String deviceId;

  const RefrigeratorControlPage({super.key, required this.deviceId});

  @override
  State<RefrigeratorControlPage> createState() => _RefrigeratorControlPageState();
}

class _RefrigeratorControlPageState extends State<RefrigeratorControlPage> {
  int _fridgeTemperature = 37; // Default fridge temperature in F
  int _freezerTemperature = 0; // Default freezer temperature in F
  String _mode = 'Normal';
  bool _quickCool = false;
  bool _quickFreeze = false;
  bool _settingsChanged = false;
  bool _isUpdating = false;

  final List<String> _modes = ['Eco', 'Normal', 'Vacation', 'Max Cooling'];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load current device settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeviceSettings();
    });

    // Set up timer to refresh the UI every 5 seconds to show updated usage
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadDeviceSettings() {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.devicesStatus == DataStatus.success) {
      try {
        final device = appState.devices.firstWhere((d) => d.id == widget.deviceId);

        if (device.settings != null) {
          if (!mounted) return;
          setState(() {
            _fridgeTemperature = device.settings!['fridgeTemperature'] as int? ?? 37;
            _freezerTemperature = device.settings!['freezerTemperature'] as int? ?? 0;
            _mode = device.settings!['mode'] as String? ?? 'Normal';
            _quickCool = device.settings!['quickCool'] as bool? ?? false;
            _quickFreeze = device.settings!['quickFreeze'] as bool? ?? false;
            _settingsChanged = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading refrigerator settings for ${widget.deviceId}: $e");
      }
    }
  }

  Future<void> _saveSettings(AppState appState) async {
    if (!_settingsChanged) return;

    setState(() {
      _isUpdating = true;
    });

    final success = await appState.updateDeviceSettings(widget.deviceId, {
      'fridgeTemperature': _fridgeTemperature,
      'freezerTemperature': _freezerTemperature,
      'mode': _mode,
      'quickCool': _quickCool,
      'quickFreeze': _quickFreeze,
    });

    setState(() {
      _isUpdating = false;
      if (success) {
        _settingsChanged = false;
      }
    });

    // Show error if update failed
    if (!success && mounted) {
      ErrorHandler.handleError(
        context,
        message: 'Failed to update refrigerator settings',
        technicalDetails: 'Please try again later.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Handle case where device isn't found
    if (appState.devicesStatus == DataStatus.loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Refrigerator'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: const Center(
          child: OptimizedLoadingIndicator(),
        ),
      );
    }

    // Try to find the device
    late Device device;
    try {
      device = appState.devices.firstWhere((d) => d.id == widget.deviceId);
    } catch (e) {
      // Device not found - show error
      return Scaffold(
        appBar: AppBar(
          title: const Text('Refrigerator'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Device not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The device may have been removed or is unavailable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_settingsChanged)
            TextButton.icon(
              onPressed: _isUpdating ? null : () => _saveSettings(appState),
              icon: _isUpdating
                  ? const OptimizedLoadingIndicator(
                      size: 18,
                    )
                  : const Icon(Icons.save),
              label: Text(_isUpdating ? 'Saving...' : 'Save'),
            ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: AppTheme.getSecondaryColor(context),
            ),
            onPressed: () {
              // Show device info dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(device.name),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${device.type}'),
                      Text('Location: ${device.room}'),
                      Text('Status: ${device.isActive ? 'On' : 'Off'}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Refrigerator Status
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                color: AppTheme.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Power',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    device.isActive ? 'On' : 'Off',
                  ),
                  value: device.isActive,
                  onChanged: (value) {
                    // Toggle power state
                    appState.toggleDevice(widget.deviceId);
                  },
                  secondary: Icon(
                    Icons.power_settings_new,
                    color: device.isActive
                        ? AppTheme.getPrimaryColor(context)
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fridge Temperature Control
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                color: AppTheme.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.kitchen_outlined,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Fridge Temperature',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: device.isActive && _fridgeTemperature > 33
                                ? () {
                                    setState(() {
                                      _fridgeTemperature -= 1;
                                      _settingsChanged = true;
                                    });
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_fridgeTemperature°F',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: device.isActive && _fridgeTemperature < 42
                                ? () {
                                    setState(() {
                                      _fridgeTemperature += 1;
                                      _settingsChanged = true;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.getPrimaryColor(context),
                          inactiveTrackColor: AppTheme.getPrimaryColor(context).withAlpha(51),
                          thumbColor: AppTheme.getPrimaryColor(context),
                          overlayColor: AppTheme.getPrimaryColor(context).withAlpha(26),
                        ),
                        child: Slider(
                          min: 33,
                          max: 42,
                          divisions: 9,
                          value: _fridgeTemperature.toDouble(),
                          onChanged: device.isActive
                              ? (value) {
                                  setState(() {
                                    _fridgeTemperature = value.round();
                                    _settingsChanged = true;
                                  });
                                }
                              : null,
                        ),
                      ),

                      // Quick Cool Switch
                      SwitchListTile(
                        title: const Text(
                          'Quick Cool',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Rapidly cool new items',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _quickCool,
                        onChanged: device.isActive
                            ? (value) {
                                setState(() {
                                  _quickCool = value;
                                  _settingsChanged = true;
                                });
                              }
                            : null,
                        secondary: Icon(
                          Icons.ac_unit,
                          color: _quickCool && device.isActive
                              ? AppTheme.getPrimaryColor(context)
                              : Theme.of(context).disabledColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Freezer Temperature Control
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                color: AppTheme.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.ac_unit,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Freezer Temperature',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: device.isActive && _freezerTemperature > -10
                                ? () {
                                    setState(() {
                                      _freezerTemperature -= 1;
                                      _settingsChanged = true;
                                    });
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_freezerTemperature°F',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: device.isActive && _freezerTemperature < 5
                                ? () {
                                    setState(() {
                                      _freezerTemperature += 1;
                                      _settingsChanged = true;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.getPrimaryColor(context),
                          inactiveTrackColor: AppTheme.getPrimaryColor(context).withAlpha(51),
                          thumbColor: AppTheme.getPrimaryColor(context),
                          overlayColor: AppTheme.getPrimaryColor(context).withAlpha(26),
                        ),
                        child: Slider(
                          min: -10,
                          max: 5,
                          divisions: 15,
                          value: _freezerTemperature.toDouble(),
                          onChanged: device.isActive
                              ? (value) {
                                  setState(() {
                                    _freezerTemperature = value.round();
                                    _settingsChanged = true;
                                  });
                                }
                              : null,
                        ),
                      ),

                      // Quick Freeze Switch
                      SwitchListTile(
                        title: const Text(
                          'Quick Freeze',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Rapidly freeze fresh items',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _quickFreeze,
                        onChanged: device.isActive
                            ? (value) {
                                setState(() {
                                  _quickFreeze = value;
                                  _settingsChanged = true;
                                });
                              }
                            : null,
                        secondary: Icon(
                          Icons.ac_unit,
                          color: _quickFreeze && device.isActive
                              ? AppTheme.getPrimaryColor(context)
                              : Theme.of(context).disabledColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mode Selection
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                color: AppTheme.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _modes.map((mode) {
                          final isSelected = mode == _mode;
                          return ChoiceChip(
                            label: Text(mode),
                            selected: isSelected,
                            onSelected: device.isActive
                                ? (selected) {
                                    if (selected) {
                                      setState(() {
                                        _mode = mode;
                                        _settingsChanged = true;
                                      });
                                    }
                                  }
                                : null,
                            selectedColor: AppTheme.getPrimaryColor(context).withAlpha(51),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.getPrimaryColor(context)
                                  : AppTheme.getTextPrimaryColor(context),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Energy Usage Chart
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                color: AppTheme.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Energy Usage',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current: ${device.currentUsage.toStringAsFixed(1)} kWh',
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Energy Usage Chart',
                            style: TextStyle(
                              color: AppTheme.getTextSecondaryColor(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
