import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'dart:math' as math; // Unused import
import '../../models/app_state.dart';
import '../../models/data_status.dart'; // Import DataStatus
import '../../theme.dart';
import '../../widgets/optimized_loading_indicator.dart';
import '../../utils/error_handler.dart'; // Import ErrorHandler

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
      'color': const Color(0xFFFFF4E5), // Warm White
    },
    {
      'name': 'Movie',
      'icon': Icons.movie,
      'brightness': 20,
      'colorTemp': 3000,
      'color': const Color(0xFFFFE0C0), // Dim Warm
    },
    {
      'name': 'Party',
      'icon': Icons.celebration,
      'brightness': 85,
      'colorTemp': 4500,
      'color': Colors.deepPurpleAccent, // Party Color
    },
    {
      'name': 'Focus',
      'icon': Icons.psychology,
      'brightness': 90,
      'colorTemp': 5500,
      'color': const Color(0xFFE0F4FF), // Cool White
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
    // Add mounted check
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    // Only try loading settings if the device list is successfully loaded
    if (appState.devicesStatus == DataStatus.success) {
      try {
        final device = appState.devices.firstWhere((d) => d.id == widget.deviceId);

        if (device is SmartLight && device.settings != null) {
          // Check mounted again before setState
          if (!mounted) return;
          setState(() {
            _brightness = device.settings!['brightness'] as int;
            _colorTemperature = device.settings!['colorTemperature'] as int;
            _selectedScene = device.settings!['scene'] as String;
            final colorValue = device.settings!['color'] as int;
            _selectedColor = Color(colorValue);
            _settingsChanged = false; // Reset changed flag after loading
          });
        }
      } catch (e) {
        // Handle case where device might not be found even if list is loaded
        debugPrint("Error loading device settings for ${widget.deviceId}: $e");
        // Optionally show a snackbar or set an error state if needed,
        // but the build method will handle the primary "not found" case.
      }
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
      'color': _selectedColor.toARGB32(), // Use toARGB32() instead of deprecated .value
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
        backgroundColor: success ? AppTheme.getSuccessColor(context) : AppTheme.getErrorColor(context), // Use theme colors
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Handle overall device list loading/error states first
    switch (appState.devicesStatus) {
      case DataStatus.initial:
      case DataStatus.loading:
        return Scaffold(
          appBar: AppBar(title: const Text('Loading Device...')),
          body: const Center(child: OptimizedLoadingIndicator()),
        );
      case DataStatus.error:
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: ErrorHandler.buildErrorDisplay(
              context: context,
              message: appState.devicesError ?? 'Failed to load devices.',
              // Optionally add retry for the device list itself if AppState supports it
            ),
          ),
        );
      case DataStatus.empty:
      case DataStatus.success:
        // Try to find the specific device
        try {
          final device = appState.devices.firstWhere((d) => d.id == widget.deviceId);
          // If found, build the controls UI
          return _buildDeviceControls(context, appState, device);
        } catch (e) {
          // Device not found in the list
          return Scaffold(
            appBar: AppBar(title: const Text('Device Not Found')),
            body: Center(
              child: ErrorHandler.buildErrorDisplay(
                context: context,
                message: 'Device with ID ${widget.deviceId} could not be found.',
                // Remove onRetry for "Device Not Found" - user should use back button.
                // onRetry: () => Navigator.of(context).pop(),
              ),
            ),
          );
        }
    }
  }

  // Extracted method to build the main UI when the device is found
  Widget _buildDeviceControls(BuildContext context, AppState appState, Device device) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate background color based on current state
    Color bgColor = _calculateBackgroundColor(isDarkMode);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(device.name),
        backgroundColor: Colors.transparent, // Keep transparent
        elevation: 0,
        foregroundColor: AppTheme.getTextPrimaryColor(context), // Use theme text color
        actions: [
          if (_settingsChanged && !_isUpdating) // Show save only if changed and not updating
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Settings',
              onPressed: () => _saveSettings(appState),
            ),
          if (_isUpdating) // Show loading indicator in AppBar while updating
             Padding(
               padding: const EdgeInsets.only(right: 16.0),
               child: Center(child: OptimizedLoadingIndicator(size: 20, color: AppTheme.getTextPrimaryColor(context))), // Use theme text color
             ),
        ],
      ),
      body: RefreshIndicator( // Allow pull-to-refresh for device state
        onRefresh: () async {
           // Trigger a state refresh, AppState simulation might update automatically
           // or we might need a specific refresh method in AppState later.
           if (mounted) setState(() {});
        },
        child: ListView( // Keep ListView for scrollability
          padding: const EdgeInsets.all(16.0),
          children: [
            // Light visualization
            _buildLightVisualization(device, context),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Prevent toggling while settings are being updated
          if (!_isUpdating) {
             appState.toggleDevice(widget.deviceId);
          }
        },
        backgroundColor: device.isActive ? AppTheme.getErrorColor(context) : AppTheme.getPrimaryColor(context), // Use theme colors
        tooltip: device.isActive ? 'Turn Off' : 'Turn On',
        child: Icon(device.isActive ? Icons.power_settings_new : Icons.power, color: Theme.of(context).colorScheme.onPrimary), // Ensure icon contrast
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Helper to calculate background color based on current settings

  Color _calculateBackgroundColor(bool isDarkMode) {
     Color bgColor;
     if (_selectedScene == 'Normal' ||
         _selectedScene == 'Reading' ||
         _selectedScene == 'Focus') {
       // Use color temperature for white light modes
       double factor = (_colorTemperature - 2700) / (6500 - 2700);
       factor = factor.clamp(0.0, 1.0);

       if (isDarkMode) {
         bgColor = Color.lerp(const Color(0xFF3A2E1D), const Color(0xFF1D2A3A), factor)!;
       } else {
         bgColor = Color.lerp(const Color(0xFFFFF4E5), const Color(0xFFE8F3FF), factor)!;
       }
     } else {
       // Use selected color for colored scenes but make it very light/dark
       if (isDarkMode) {
         bgColor = Color.alphaBlend(_selectedColor.withAlpha((0.15 * 255).round()), AppTheme.darkBackgroundColor);
       } else {
         bgColor = Color.alphaBlend(_selectedColor.withAlpha((0.1 * 255).round()), Theme.of(context).colorScheme.surface); // Use theme surface
       }
     }
     return bgColor;
  }

  Widget _buildLightVisualization(Device device, BuildContext context) {
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Unused variable
    final bulbColor =
        device.isActive
            ? _getLightColor()
            : Theme.of(context).disabledColor.withAlpha((0.3 * 255).round()); // Use theme color
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
                    color: bulbColor.withAlpha((glowOpacity * 255).round()),
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
                          color: Theme.of(context).shadowColor.withAlpha((0.1 * 255).round()), // Use theme shadow
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
                        ? Theme.of(context).colorScheme.onPrimary.withAlpha((0.9 * 255).round()) // Use theme color
                        : Theme.of(context).disabledColor, // Use theme color
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

  Color _getColorForTemperature() {
    // Map color temperature (2700K-6500K) to a color
    double factor = (_colorTemperature - 2700) / (6500 - 2700);
    factor = factor.clamp(0.0, 1.0);

    // Warm (amber) to cool (white-blue)
    return Color.lerp(
      const Color(0xFFFFD28F), // Warm color (2700K)
      const Color(0xFFD6ECFF), // Cool color (6500K)
      factor,
    )!;
  }

  Widget _buildBrightnessControl(Device device) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color:
          isDarkMode
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.8 * 255).round()) // Use theme color
              : Theme.of(context).colorScheme.surface.withAlpha((0.8 * 255).round()), // Use theme color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brightness',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.brightness_low,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
                Expanded(
                  child: Slider(
                    value: _brightness.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor:
                        device.isActive
                            ? AppTheme.getPrimaryColor(context)
                            : Theme.of(context).disabledColor, // Use theme color
                    inactiveColor: AppTheme.getPrimaryColor(
                      context,
                    ).withAlpha((0.2 * 255).round()), // Keep primary accent for inactive track
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
                Icon(
                  Icons.brightness_high,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ],
            ),
            Center(
              child: Text(
                '$_brightness%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTemperatureControl() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Format the temperature value for display
    String displayTemp;
    if (_colorTemperature >= 1000) {
      displayTemp = '${(_colorTemperature / 1000).toStringAsFixed(1)}K';
    } else {
      displayTemp = '${_colorTemperature}K';
    }

    return Card(
      elevation: 0,
      color:
          isDarkMode
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.8 * 255).round()) // Use theme color
              : Theme.of(context).colorScheme.surface.withAlpha((0.8 * 255).round()), // Use theme color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Temperature',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
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
                    color: const Color(0xFFFFD28F), // Keep specific color for warm end
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).dividerColor, // Use theme divider color
                    ),
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
                    color: const Color(0xFFD6ECFF), // Keep specific color for cool end
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).dividerColor, // Use theme divider color
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: Text(
                displayTemp,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Warm',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                Text(
                  'Cool',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneSelection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color:
          isDarkMode
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.8 * 255).round()) // Use theme color
              : Theme.of(context).colorScheme.surface.withAlpha((0.8 * 255).round()), // Use theme color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scenes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
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
                              ? AppTheme.getPrimaryColor(
                                context,
                              ).withAlpha((0.1 * 255).round())
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()), // Use theme color
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.getPrimaryColor(context)
                                : Colors.transparent, // Keep transparent for non-selected border
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
                                    ? AppTheme.getPrimaryColor(context)
                                    : Theme.of(context).colorScheme.surfaceContainerHighest, // Use theme color
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            scene['icon'] as IconData,
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.onPrimary // Use theme color
                                    : AppTheme.getTextSecondaryColor(context),
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
                                    ? AppTheme.getPrimaryColor(context)
                                    : AppTheme.getTextSecondaryColor(context),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color:
          isDarkMode
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.8 * 255).round()) // Use theme color
              : Theme.of(context).colorScheme.surface.withAlpha((0.8 * 255).round()), // Use theme color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Group Control',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha((0.1 * 255).round()),
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
            ListTile(
              leading: Icon(
                Icons.lightbulb,
                color: AppTheme.getTextSecondaryColor(context),
              ),
              title: Text(
                'Living Room Lights',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              subtitle: Text(
                '3 lights',
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.getTextSecondaryColor(context),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(
                Icons.lightbulb,
                color: AppTheme.getTextSecondaryColor(context),
              ),
              title: Text(
                'Bedroom Lights',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              subtitle: Text(
                '2 lights',
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.getTextSecondaryColor(context),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color:
          isDarkMode
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.8 * 255).round()) // Use theme color
              : Theme.of(context).colorScheme.surface.withAlpha((0.8 * 255).round()), // Use theme color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha((0.1 * 255).round()),
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
              icon: Icon(Icons.add),
              label: Text('Add Schedule'),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppTheme.getPrimaryColor(context),
                backgroundColor: Theme.of(context).colorScheme.surface, // Use theme surface color
                side: BorderSide(color: AppTheme.getPrimaryColor(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
