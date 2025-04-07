import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../models/app_state.dart';
import '../../theme.dart';

class LightControlPage extends StatefulWidget {
  final String deviceId;

  const LightControlPage({super.key, required this.deviceId});

  @override
  State<LightControlPage> createState() => _LightControlPageState();
}

class _LightControlPageState extends State<LightControlPage> {
  int _brightness = 80; // 0-100
  int _colorTemperature = 4000; // 2700-6500K
  String _selectedScene = 'Normal';
  Color _selectedColor = Colors.white;
  bool _settingsChanged = false;
  bool _isUpdating = false;

  final List<Map<String, dynamic>> _scenes = [
    {
      'name': 'Normal',
      'icon': Icons.lightbulb_outline,
      'brightness': 80,
      'colorTemp': 4000,
      'color': Colors.white,
    },
    {
      'name': 'Reading',
      'icon': Icons.book,
      'brightness': 100,
      'colorTemp': 5000,
      'color': Colors.white,
    },
    {
      'name': 'Relaxing',
      'icon': Icons.spa,
      'brightness': 40,
      'colorTemp': 2700,
      'color': const Color(0xFFFFF4E5),
    },
    {
      'name': 'Movie',
      'icon': Icons.movie,
      'brightness': 20,
      'colorTemp': 3000,
      'color': const Color(0xFFFFE0C0),
    },
    {
      'name': 'Party',
      'icon': Icons.celebration,
      'brightness': 85,
      'colorTemp': 4500,
      'color': Colors.deepPurpleAccent,
    },
    {
      'name': 'Focus',
      'icon': Icons.psychology,
      'brightness': 90,
      'colorTemp': 5500,
      'color': const Color(0xFFE0F4FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Load current device settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeviceSettings();
    });
  }

  void _loadDeviceSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    final device = appState.devices.firstWhere((d) => d.id == widget.deviceId);

    if (device is SmartLight && device.settings != null) {
      setState(() {
        _brightness = device.settings!['brightness'] as int;
        _colorTemperature = device.settings!['colorTemperature'] as int;
        _selectedScene = device.settings!['scene'] as String;

        final colorValue = device.settings!['color'] as int;
        _selectedColor = Color(colorValue);
      });
    }
  }

  void _applyScene(String sceneName) {
    final scene = _scenes.firstWhere((scene) => scene['name'] == sceneName);

    setState(() {
      _selectedScene = sceneName;
      _brightness = scene['brightness'] as int;
      _colorTemperature = scene['colorTemp'] as int;
      _selectedColor = scene['color'] as Color;
      _settingsChanged = true;
    });
  }

  Future<void> _saveSettings(AppState appState) async {
    if (!_settingsChanged) return;

    setState(() {
      _isUpdating = true;
    });

    final success = await appState.updateDeviceSettings(widget.deviceId, {
      'brightness': _brightness,
      'colorTemperature': _colorTemperature,
      'scene': _selectedScene,
      'color': _selectedColor.value,
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
            type: 'Light',
            isActive: false,
            currentUsage: 0,
            iconPath: 'lightbulb',
            maxUsage: 0,
          ),
    );

    if (device.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Not Found')),
        body: const Center(child: Text('The device could not be found.')),
      );
    }

    // Calculate background color based on color temperature and selected color
    Color bgColor;
    if (_selectedScene == 'Normal' ||
        _selectedScene == 'Reading' ||
        _selectedScene == 'Focus') {
      // Use color temperature for white light modes
      double factor = (_colorTemperature - 2700) / (6500 - 2700);
      factor = factor.clamp(0.0, 1.0);

      // Warm (2700K) to cool (6500K)
      bgColor =
          Color.lerp(
            const Color(0xFFFFF4E5), // Warm
            const Color(0xFFE8F3FF), // Cool
            factor,
          )!;
    } else {
      // Use selected color for colored scenes but make it very light
      bgColor = Color.alphaBlend(_selectedColor.withOpacity(0.1), Colors.white);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(device.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              // Light visualization
              _buildLightVisualization(device),

              const SizedBox(height: 24),

              // Brightness control
              _buildBrightnessControl(device),

              const SizedBox(height: 24),

              // Color temperature slider
              _buildColorTemperatureControl(),

              const SizedBox(height: 24),

              // Scene selection
              _buildSceneSelection(),

              const SizedBox(height: 24),

              // Group control placeholder
              _buildGroupControl(),

              const SizedBox(height: 24),

              // Schedule settings placeholder
              _buildScheduleSection(),

              const SizedBox(height: 80), // Bottom padding for FAB
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

  Widget _buildLightVisualization(Device device) {
    final bulbColor = device.isActive ? _getLightColor() : Colors.grey.shade300;

    final glowOpacity = device.isActive ? (_brightness / 100) * 0.8 : 0.0;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          if (device.isActive)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bulbColor.withOpacity(glowOpacity),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

          // Lightbulb
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bulbColor,
              boxShadow:
                  device.isActive
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Icon(
                Icons.lightbulb,
                size: 60,
                color:
                    device.isActive
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLightColor() {
    if (_selectedScene == 'Normal' ||
        _selectedScene == 'Reading' ||
        _selectedScene == 'Focus') {
      // Use color temperature for white light
      double factor = (_colorTemperature - 2700) / (6500 - 2700);
      factor = factor.clamp(0.0, 1.0);

      // Warm (amber) to cool (white-blue)
      return Color.lerp(
        const Color(0xFFFFD28F), // Warm
        const Color(0xFFD6ECFF), // Cool
        factor,
      )!;
    } else {
      // Use selected color for colored scenes
      return _selectedColor;
    }
  }

  Widget _buildBrightnessControl(Device device) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brightness',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.brightness_low,
                  color: AppTheme.textSecondaryColor,
                ),
                Expanded(
                  child: Slider(
                    value: _brightness.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor:
                        device.isActive ? AppTheme.primaryColor : Colors.grey,
                    inactiveColor: AppTheme.primaryColor.withOpacity(0.2),
                    onChanged:
                        !device.isActive
                            ? null
                            : (value) {
                              setState(() {
                                _brightness = value.round();
                                _settingsChanged = true;

                                // Reset scene selection if changing brightness
                                if (_scenes.any(
                                  (scene) =>
                                      scene['name'] == _selectedScene &&
                                      scene['brightness'] != _brightness,
                                )) {
                                  _selectedScene = 'Custom';
                                }
                              });
                            },
                  ),
                ),
                const Icon(
                  Icons.brightness_high,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
            Center(
              child: Text(
                '$_brightness%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTemperatureControl() {
    // Format the temperature value for display
    String displayTemp;
    if (_colorTemperature >= 1000) {
      displayTemp = '${(_colorTemperature / 1000).toStringAsFixed(1)}K';
    } else {
      displayTemp = '${_colorTemperature}K';
    }

    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color Temperature',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD28F),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _colorTemperature.toDouble(),
                    min: 2700,
                    max: 6500,
                    divisions: 38,
                    activeColor: _getColorForTemperature(),
                    onChanged: (value) {
                      setState(() {
                        _colorTemperature = value.round();
                        _settingsChanged = true;

                        // Reset scene selection if changing color temperature
                        if (_scenes.any(
                          (scene) =>
                              scene['name'] == _selectedScene &&
                              scene['colorTemp'] != _colorTemperature,
                        )) {
                          _selectedScene = 'Custom';
                        }
                      });
                    },
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6ECFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
            Center(
              child: Text(
                displayTemp,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Warm',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Text(
                  'Cool',
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

  Color _getColorForTemperature() {
    double factor = (_colorTemperature - 2700) / (6500 - 2700);
    return Color.lerp(
      const Color(0xFFFFD28F), // Warm
      const Color(0xFFD6ECFF), // Cool
      factor,
    )!;
  }

  Widget _buildSceneSelection() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scenes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _scenes.length,
              itemBuilder: (context, index) {
                final scene = _scenes[index];
                final isSelected = _selectedScene == scene['name'];

                return GestureDetector(
                  onTap: () {
                    _applyScene(scene['name']);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            scene['icon'] as IconData,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scene['name'] as String,
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupControl() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
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
                  'Group Control',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.lightbulb, color: Colors.grey),
              title: Text('Living Room Lights'),
              subtitle: Text('3 lights'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              leading: Icon(Icons.lightbulb, color: Colors.grey),
              title: Text('Bedroom Lights'),
              subtitle: Text('2 lights'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
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
                  'Schedules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Schedule feature coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
