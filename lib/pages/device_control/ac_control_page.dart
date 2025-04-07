import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/app_state.dart';
import '../../theme.dart';
import '../../widgets/usage_chart.dart';

class ACControlPage extends StatefulWidget {
  final String deviceId;

  const ACControlPage({super.key, required this.deviceId});

  @override
  State<ACControlPage> createState() => _ACControlPageState();
}

class _ACControlPageState extends State<ACControlPage> {
  int _temperature = 24;
  String _fanSpeed = 'Medium';
  String _mode = 'Cool';
  int _timerHours = 0;
  bool _settingsChanged = false;
  bool _isUpdating = false;

  final List<String> _fanSpeeds = ['Low', 'Medium', 'High', 'Auto'];
  final List<String> _modes = ['Cool', 'Heat', 'Fan', 'Auto'];
  final List<int> _timerOptions = [0, 1, 2, 4, 8];

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
    final appState = Provider.of<AppState>(context, listen: false);
    final device = appState.devices.firstWhere((d) => d.id == widget.deviceId);

    if (device is SmartAC && device.settings != null) {
      setState(() {
        _temperature = device.settings!['temperature'] as int;
        _fanSpeed = device.settings!['fanSpeed'] as String;
        _mode = device.settings!['mode'] as String;
        _timerHours = device.settings!['timerHours'] as int;
      });
    }
  }

  Future<void> _saveSettings(AppState appState) async {
    if (!_settingsChanged) return;

    setState(() {
      _isUpdating = true;
    });

    final success = await appState.updateDeviceSettings(widget.deviceId, {
      'temperature': _temperature,
      'fanSpeed': _fanSpeed,
      'mode': _mode,
      'timerHours': _timerHours,
    });

    setState(() {
      _isUpdating = false;
      _settingsChanged = false;
    });

    // Show success/failure message
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Settings updated successfully'
              : 'Failed to update settings. Please try again.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final device = appState.devices.firstWhere(
      (d) => d.id == widget.deviceId,
      orElse:
          () => Device(
            id: '',
            name: 'Unknown Device',
            type: 'HVAC',
            isActive: false,
            currentUsage: 0,
            iconPath: 'ac_unit',
            maxUsage: 0,
          ),
    );

    if (device.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Not Found')),
        body: const Center(child: Text('The device could not be found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          if (_settingsChanged)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isUpdating ? null : () => _saveSettings(appState),
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Device status card
              _buildStatusCard(device),

              const SizedBox(height: 20),

              // Temperature control
              _buildTemperatureControl(device),

              const SizedBox(height: 20),

              // Fan speed and mode selection
              _buildControlOptions(device),

              const SizedBox(height: 20),

              // Timer settings
              _buildTimerSettings(device),

              const SizedBox(height: 20),

              // Power usage chart
              _buildPowerUsageChart(device),

              const SizedBox(height: 100), // Bottom padding for FAB
            ],
          ),

          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          appState.toggleDevice(widget.deviceId);
        },
        backgroundColor: device.isActive ? Colors.red : AppTheme.primaryColor,
        child: Icon(device.isActive ? Icons.power_settings_new : Icons.power),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusCard(Device device) {
    final modeColor = _getModeColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    device.isActive
                        ? modeColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.ac_unit,
                size: 32,
                color: device.isActive ? modeColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
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
                        device.isActive ? 'Active' : 'Off',
                        style: TextStyle(
                          color:
                              device.isActive
                                  ? Colors.green
                                  : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      size: 16,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${device.currentUsage.toStringAsFixed(0)} W',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: modeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _mode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: modeColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getModeColor() {
    switch (_mode) {
      case 'Cool':
        return Colors.blue;
      case 'Heat':
        return Colors.orange;
      case 'Fan':
        return Colors.teal;
      case 'Auto':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildTemperatureControl(Device device) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Temperature',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minus button
                _buildTemperatureButton(
                  icon: Icons.remove,
                  onPressed:
                      !device.isActive
                          ? null
                          : () {
                            if (_temperature > 16) {
                              setState(() {
                                _temperature--;
                                _settingsChanged = true;
                              });
                            }
                          },
                ),

                const SizedBox(width: 16),

                // Temperature display
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getTemperatureColor().withOpacity(0.1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_temperature°',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color:
                                device.isActive
                                    ? _getTemperatureColor()
                                    : Colors.grey,
                          ),
                        ),
                        Text(
                          'Celsius',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                device.isActive
                                    ? AppTheme.textSecondaryColor
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Plus button
                _buildTemperatureButton(
                  icon: Icons.add,
                  onPressed:
                      !device.isActive
                          ? null
                          : () {
                            if (_temperature < 30) {
                              setState(() {
                                _temperature++;
                                _settingsChanged = true;
                              });
                            }
                          },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Temperature slider
            Slider(
              min: 16,
              max: 30,
              divisions: 14,
              value: _temperature.toDouble(),
              activeColor:
                  device.isActive ? _getTemperatureColor() : Colors.grey,
              inactiveColor: Colors.grey.withOpacity(0.2),
              onChanged:
                  !device.isActive
                      ? null
                      : (value) {
                        setState(() {
                          _temperature = value.round();
                          _settingsChanged = true;
                        });
                      },
            ),
            // Temperature range labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '16°C',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const Text(
                    '30°C',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
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

  Widget _buildTemperatureButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color:
              onPressed == null
                  ? Colors.grey.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
        ),
        child: Center(
          child: Icon(
            icon,
            color: onPressed == null ? Colors.grey : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Color _getTemperatureColor() {
    if (_mode == 'Cool') {
      // Cooler temperatures are more blue
      if (_temperature <= 20) {
        return Colors.blue;
      } else if (_temperature <= 24) {
        return Colors.lightBlue;
      } else {
        return Colors.cyan;
      }
    } else if (_mode == 'Heat') {
      // Warmer temperatures are more orange/red
      if (_temperature >= 26) {
        return Colors.deepOrange;
      } else if (_temperature >= 22) {
        return Colors.orange;
      } else {
        return Colors.amber;
      }
    } else {
      return AppTheme.primaryColor;
    }
  }

  Widget _buildControlOptions(Device device) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _mode,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(8),
                            onChanged:
                                !device.isActive
                                    ? null
                                    : (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _mode = newValue;
                                          _settingsChanged = true;
                                        });
                                      }
                                    },
                            items:
                                _modes.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fan Speed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _fanSpeed,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(8),
                            onChanged:
                                !device.isActive
                                    ? null
                                    : (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _fanSpeed = newValue;
                                          _settingsChanged = true;
                                        });
                                      }
                                    },
                            items:
                                _fanSpeeds.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.air,
                      size: 18,
                      color: AppTheme.textSecondaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Swing',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Switch(
                  value: false, // Placeholder for swing feature
                  onChanged:
                      !device.isActive
                          ? null
                          : (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Swing feature coming soon'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.nights_stay,
                      size: 18,
                      color: AppTheme.textSecondaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Sleep Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Switch(
                  value: false, // Placeholder for sleep mode
                  onChanged:
                      !device.isActive
                          ? null
                          : (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sleep mode feature coming soon'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSettings(Device device) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  _timerOptions.map((hours) {
                    final isSelected = _timerHours == hours;
                    final isEnabled = device.isActive;

                    return GestureDetector(
                      onTap:
                          !isEnabled
                              ? null
                              : () {
                                setState(() {
                                  _timerHours = hours;
                                  _settingsChanged = true;
                                });
                              },
                      child: Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              !isEnabled
                                  ? Colors.grey.withOpacity(0.1)
                                  : isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              hours == 0 ? 'Off' : '$hours',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    !isEnabled
                                        ? Colors.grey
                                        : isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (hours > 0)
                              Text(
                                'hour${hours == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      !isEnabled
                                          ? Colors.grey
                                          : isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : AppTheme.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            if (_timerHours > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Text(
                    'AC will turn off in $_timerHours hour${_timerHours == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerUsageChart(Device device) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Power Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: ${device.currentUsage.toStringAsFixed(0)} W',
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
                Text(
                  'Max: ${device.maxUsage.toStringAsFixed(0)} W',
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: UsageChart(
                data: device.usageHistory,
                lineColor: _getModeColor(),
                fillColor: _getModeColor().withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '24h ago',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Text(
                  'Now',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
