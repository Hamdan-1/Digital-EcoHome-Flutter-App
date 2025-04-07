import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/app_state.dart';
import '../../theme.dart';

class WashingMachineControlPage extends StatefulWidget {
  final String deviceId;

  const WashingMachineControlPage({super.key, required this.deviceId});

  @override
  State<WashingMachineControlPage> createState() =>
      _WashingMachineControlPageState();
}

class _WashingMachineControlPageState extends State<WashingMachineControlPage> {
  final List<String> _cycles = ['Normal', 'Heavy', 'Delicate', 'Quick'];
  final List<String> _temperatures = ['Cold', 'Warm', 'Hot'];
  final List<String> _spinSpeeds = ['Low', 'Medium', 'High'];

  String _selectedCycle = 'Normal';
  String _selectedTemperature = 'Warm';
  String _selectedSpinSpeed = 'Medium';
  int _remainingMinutes = 45;
  double _progress = 0.0;
  bool _isRunning = false;
  bool _settingsChanged = false;
  bool _isUpdating = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    // Load current device settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeviceSettings();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _loadDeviceSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    final device = appState.devices.firstWhere((d) => d.id == widget.deviceId);

    if (device is SmartWashingMachine && device.settings != null) {
      setState(() {
        _selectedCycle = device.settings!['cycle'] as String;
        _selectedTemperature = device.settings!['temperature'] as String;
        _selectedSpinSpeed = device.settings!['spinSpeed'] as String;
        _remainingMinutes = device.settings!['remainingMinutes'] as int;
        _progress = device.settings!['progress'] as double;
        _isRunning = device.settings!['isRunning'] as bool;
      });

      if (_isRunning && device.isActive) {
        _startProgressTimer();
      }
    }
  }

  void _startProgressTimer() {
    // Cancel any existing timer
    _progressTimer?.cancel();

    // Only start the timer if there is remaining time
    if (_remainingMinutes > 0) {
      // Update progress every 3 seconds (simulated)
      _progressTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final appState = Provider.of<AppState>(context, listen: false);
        final device = appState.devices.firstWhere(
          (d) => d.id == widget.deviceId,
          orElse:
              () => Device(
                id: '',
                name: 'Unknown Device',
                type: 'Appliance',
                isActive: false,
                currentUsage: 0,
                iconPath: 'local_laundry_service',
                maxUsage: 0,
              ),
        );

        if (!device.isActive || device.id.isEmpty) {
          timer.cancel();
          setState(() {
            _isRunning = false;
          });
          return;
        }

        setState(() {
          // Update progress
          double progressIncrement =
              1.0 / (_getCycleDuration() * 20); // 20 updates per cycle
          _progress = (_progress + progressIncrement).clamp(0.0, 1.0);

          // Update remaining minutes
          int elapsedMinutes = (_getCycleDuration() * _progress).round();
          _remainingMinutes = _getCycleDuration() - elapsedMinutes;

          // Check if cycle is complete
          if (_progress >= 1.0) {
            _isRunning = false;
            _progress = 1.0;
            _remainingMinutes = 0;
            timer.cancel();

            // Update device settings
            appState.updateDeviceSettings(widget.deviceId, {
              'progress': _progress,
              'remainingMinutes': _remainingMinutes,
              'isRunning': _isRunning,
            });

            // Show completion notification
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Washing cycle complete!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });

        // Update device settings with current progress
        appState.updateDeviceSettings(widget.deviceId, {
          'progress': _progress,
          'remainingMinutes': _remainingMinutes,
          'isRunning': _isRunning,
        });
      });
    }
  }

  int _getCycleDuration() {
    switch (_selectedCycle) {
      case 'Quick':
        return 30;
      case 'Delicate':
        return 40;
      case 'Normal':
        return 45;
      case 'Heavy':
        return 60;
      default:
        return 45;
    }
  }

  void _resetCycle() {
    setState(() {
      _progress = 0.0;
      _remainingMinutes = _getCycleDuration();
      _isRunning = false;
      _progressTimer?.cancel();
    });
  }

  void _toggleRunning(AppState appState) async {
    if (!appState.devices.firstWhere((d) => d.id == widget.deviceId).isActive) {
      // If device is off, turn it on first
      appState.toggleDevice(widget.deviceId);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _isUpdating = true;
    });

    // Toggle running state
    final newRunningState = !_isRunning;

    // Reset cycle if starting new
    if (newRunningState && _progress >= 1.0) {
      _resetCycle();
    }

    // Update device settings
    final success = await appState.updateDeviceSettings(widget.deviceId, {
      'cycle': _selectedCycle,
      'temperature': _selectedTemperature,
      'spinSpeed': _selectedSpinSpeed,
      'remainingMinutes': _remainingMinutes,
      'progress': _progress,
      'isRunning': newRunningState,
    });

    setState(() {
      _isUpdating = false;
      if (success) {
        _isRunning = newRunningState;
        _settingsChanged = false;

        if (_isRunning) {
          _startProgressTimer();
        } else {
          _progressTimer?.cancel();
        }
      }
    });

    // Show success/failure message
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? newRunningState
                  ? 'Washing cycle started'
                  : 'Washing cycle paused'
              : 'Failed to update settings. Please try again.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveSettings(AppState appState) async {
    if (!_settingsChanged) return;

    setState(() {
      _isUpdating = true;
    });

    // Reset cycle if changing settings
    _resetCycle();

    final success = await appState.updateDeviceSettings(widget.deviceId, {
      'cycle': _selectedCycle,
      'temperature': _selectedTemperature,
      'spinSpeed': _selectedSpinSpeed,
      'remainingMinutes': _getCycleDuration(),
      'progress': 0.0,
      'isRunning': false,
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
            type: 'Appliance',
            isActive: false,
            currentUsage: 0,
            iconPath: 'local_laundry_service',
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

              // Cycle progress card (if running)
              if (_isRunning || _progress > 0) _buildProgressCard(),

              const SizedBox(height: 20),

              // Cycle selection
              _buildCycleSelection(),

              const SizedBox(height: 20),

              // Temperature and spin settings
              _buildSettingsSection(),

              const SizedBox(height: 20),

              // Timer info
              _buildTimerInfo(),

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUpdating ? null : () => _toggleRunning(appState),
        backgroundColor: _getActionButtonColor(),
        icon: Icon(_getActionButtonIcon()),
        label: Text(_getActionButtonLabel()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Color _getActionButtonColor() {
    if (_isRunning) {
      return Colors.orange;
    } else if (_progress >= 1.0) {
      return Colors.blue;
    } else if (_progress > 0) {
      return Colors.green;
    } else {
      return AppTheme.primaryColor;
    }
  }

  IconData _getActionButtonIcon() {
    if (_isRunning) {
      return Icons.pause;
    } else if (_progress >= 1.0) {
      return Icons.refresh;
    } else if (_progress > 0) {
      return Icons.play_arrow;
    } else {
      return Icons.play_arrow;
    }
  }

  String _getActionButtonLabel() {
    if (_isRunning) {
      return 'Pause';
    } else if (_progress >= 1.0) {
      return 'New Cycle';
    } else if (_progress > 0) {
      return 'Resume';
    } else {
      return 'Start';
    }
  }

  Widget _buildStatusCard(Device device) {
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
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_laundry_service,
                size: 32,
                color: device.isActive ? AppTheme.primaryColor : Colors.grey,
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
                        device.isActive
                            ? _isRunning
                                ? 'Running'
                                : 'Ready'
                            : 'Off',
                        style: TextStyle(
                          color:
                              device.isActive
                                  ? _isRunning
                                      ? Colors.green
                                      : AppTheme.textSecondaryColor
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
                Text(
                  _selectedCycle,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    String statusText;
    Color statusColor;

    if (_progress >= 1.0) {
      statusText = 'Cycle Complete';
      statusColor = Colors.green;
    } else if (_isRunning) {
      statusText = 'Washing...';
      statusColor = Colors.blue;
    } else {
      statusText = 'Paused';
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progress >= 1.0 ? Colors.green : AppTheme.primaryColor,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _progress >= 1.0
                          ? 'Done'
                          : '$_remainingMinutes min remaining',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wash Cycle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  _cycles.map((cycle) {
                    final isSelected = _selectedCycle == cycle;

                    return GestureDetector(
                      onTap: () {
                        if (!_isRunning) {
                          setState(() {
                            _selectedCycle = cycle;
                            _remainingMinutes = _getCycleDuration();
                            _settingsChanged = true;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getCycleIcon(cycle),
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondaryColor,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cycle,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppTheme.textSecondaryColor,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getCycleDurationForType(cycle)} min',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isSelected
                                        ? Colors.white.withOpacity(0.8)
                                        : AppTheme.textSecondaryColor
                                            .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCycleIcon(String cycle) {
    switch (cycle) {
      case 'Quick':
        return Icons.timer;
      case 'Delicate':
        return Icons.spa;
      case 'Normal':
        return Icons.local_laundry_service;
      case 'Heavy':
        return Icons.fitness_center;
      default:
        return Icons.local_laundry_service;
    }
  }

  int _getCycleDurationForType(String cycle) {
    switch (cycle) {
      case 'Quick':
        return 30;
      case 'Delicate':
        return 40;
      case 'Normal':
        return 45;
      case 'Heavy':
        return 60;
      default:
        return 45;
    }
  }

  Widget _buildSettingsSection() {
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
                        'Temperature',
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
                            value: _selectedTemperature,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(8),
                            onChanged:
                                _isRunning
                                    ? null
                                    : (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedTemperature = newValue;
                                          _settingsChanged = true;
                                        });
                                      }
                                    },
                            items:
                                _temperatures.map<DropdownMenuItem<String>>((
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
                        'Spin Speed',
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
                            value: _selectedSpinSpeed,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(8),
                            onChanged:
                                _isRunning
                                    ? null
                                    : (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedSpinSpeed = newValue;
                                          _settingsChanged = true;
                                        });
                                      }
                                    },
                            items:
                                _spinSpeeds.map<DropdownMenuItem<String>>((
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
          ],
        ),
      ),
    );
  }

  Widget _buildTimerInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cycle Information',
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
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    title: 'Duration',
                    value: '$_remainingMinutes min',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.water_drop,
                    title: 'Temperature',
                    value: _selectedTemperature,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.rotate_right,
                    title: 'Spin',
                    value: _selectedSpinSpeed,
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
                const Text(
                  'Schedule Wash',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: false, // Placeholder for scheduling feature
                  onChanged:
                      _isRunning
                          ? null
                          : (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Scheduling feature coming soon'),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
