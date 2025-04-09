import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../models/settings/app_settings.dart';
import '../models/settings/user_preferences.dart';
import '../models/settings/home_configuration.dart';
import '../models/settings/device_management.dart';
import '../models/settings/advanced_settings.dart';
import '../providers/theme_provider.dart';
import '../widgets/dark_mode_toggle.dart';
import 'about_page.dart'; // Import the new AboutPage
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Index for the current settings tab
  int _selectedTabIndex = 0;

  // Temporary local state for form fields
  late UserPreferences _userPreferences;
  late HomeConfiguration _homeConfiguration;
  late DeviceManagement _deviceManagement;
  late AdvancedSettings _advancedSettings;
  late AboutSettings _aboutSettings;

  // Form controllers - will initialize in initState
  late TextEditingController _energyPriceController;
  late TextEditingController _homeSizeController;
  late TextEditingController _occupantsController;
  late TextEditingController _monthlyEnergyGoalController;
  late TextEditingController _monthlyCostGoalController;

  // Controller for adding new room
  final TextEditingController _newRoomNameController = TextEditingController();

  // Device being edited (if any)
  String? _editingDeviceId; // Field is used, restored

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _energyPriceController = TextEditingController();
    _homeSizeController = TextEditingController();
    _occupantsController = TextEditingController();
    _monthlyEnergyGoalController = TextEditingController();
    _monthlyCostGoalController = TextEditingController();

    // Will initialize local copies of settings from AppState in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get current settings from AppState
    final appState = Provider.of<AppState>(context, listen: false);
    _userPreferences = appState.appSettings.userPreferences;
    _homeConfiguration = appState.appSettings.homeConfiguration;
    _deviceManagement = appState.appSettings.deviceManagement;
    _advancedSettings = appState.appSettings.advancedSettings;
    _aboutSettings = appState.appSettings.aboutSettings;

    // Update controllers with current values
    _energyPriceController.text = _userPreferences.energyPricePerKwh.toString();
    _homeSizeController.text = _homeConfiguration.homeSize.toString();
    _occupantsController.text = _homeConfiguration.occupants.toString();
    _monthlyEnergyGoalController.text =
        _homeConfiguration.monthlyEnergyGoal.toString();
    _monthlyCostGoalController.text =
        _homeConfiguration.monthlyCostGoal.toString();
  }

  @override
  void dispose() {
    // Dispose controllers
    _energyPriceController.dispose();
    _homeSizeController.dispose();
    _occupantsController.dispose();
    _monthlyEnergyGoalController.dispose();
    _monthlyCostGoalController.dispose();
    _newRoomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Tab Bar for settings categories
            _buildTabBar(),

            // Tab content (expanded to fill remaining space)
            Expanded(child: _buildSelectedTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppTheme.getTextPrimaryColor(context),
            ),
            onPressed: () {
              // Search functionality could be added here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: [
          _buildTabItem('User Preferences', 0),
          _buildTabItem('Home Configuration', 1),
          _buildTabItem('Device Management', 2),
          _buildTabItem('About & Help', 3),
          _buildTabItem('Advanced', 4),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final primaryColor =
        isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildUserPreferencesTab();
      case 1:
        return _buildHomeConfigurationTab();
      case 2:
        return _buildDeviceManagementTab();
      case 3:
        return _buildAboutAndHelpTab();
      case 4:
        return _buildAdvancedSettingsTab();
      default:
        return _buildUserPreferencesTab();
    }
  }

  // User Preferences Tab
  Widget _buildUserPreferencesTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Energy cost settings section
        _buildSectionHeader('Energy Cost Settings'),
        _buildNumberInputSetting(
          title: 'Energy Price per kWh',
          subtitle: 'Set your utility\'s price per kilowatt-hour',
          controller: _energyPriceController,
          icon: Icons.attach_money,
          onChanged: (value) {
            final price = double.tryParse(value);
            if (price != null) {
              final updatedPreferences = _userPreferences.copyWith(
                energyPricePerKwh: price,
              );
              setState(() {
                _userPreferences = updatedPreferences;
              });
              _updateUserPreferences(updatedPreferences);
            }
          },
        ),
        _buildDropdownSetting<String>(
          title: 'Currency',
          subtitle: 'Select your preferred currency',
          value: _userPreferences.currency,
          items: UserPreferences.availableCurrencies,
          icon: Icons.currency_exchange,
          onChanged: (value) {
            if (value != null) {
              final updatedPreferences = _userPreferences.copyWith(
                currency: value,
              );
              setState(() {
                _userPreferences = updatedPreferences;
              });
              _updateUserPreferences(updatedPreferences);
            }
          },
        ),

        const Divider(height: 32),

        // Temperature unit section
        _buildSectionHeader('Temperature Settings'),
        _buildDropdownSetting<String>(
          title: 'Temperature Unit',
          subtitle: 'Choose between Celsius and Fahrenheit',
          value: _userPreferences.temperatureUnit,
          items: UserPreferences.availableTemperatureUnits,
          icon: Icons.thermostat,
          onChanged: (value) {
            if (value != null) {
              final updatedPreferences = _userPreferences.copyWith(
                temperatureUnit: value,
              );
              setState(() {
                _userPreferences = updatedPreferences;
              });
              _updateUserPreferences(updatedPreferences);
            }
          },
        ),

        const Divider(height: 32),

        // Notification preferences section
        _buildSectionHeader('Notification Preferences'),
        _buildSwitchSetting(
          title: 'Enable Notifications',
          subtitle: 'Master switch for all app notifications',
          value: _userPreferences.notificationsEnabled,
          icon: Icons.notifications,
          onChanged: (value) {
            final updatedPreferences = _userPreferences.copyWith(
              notificationsEnabled: value,
            );
            setState(() {
              _userPreferences = updatedPreferences;
            });
            _updateUserPreferences(updatedPreferences);
          },
        ),

        // Only show individual notification settings if master switch is on
        if (_userPreferences.notificationsEnabled) ...[
          const SizedBox(height: 8),
          _buildSwitchSetting(
            title: 'Energy Alerts',
            subtitle: 'Notify about unusual energy consumption',
            value: _userPreferences.energyAlertNotifications,
            icon: Icons.warning_amber,
            onChanged: (value) {
              final updatedPreferences = _userPreferences.copyWith(
                energyAlertNotifications: value,
              );
              setState(() {
                _userPreferences = updatedPreferences;
              });
              _updateUserPreferences(updatedPreferences);
            },
            indent: 24,
          ),
          _buildSwitchSetting(
            title: 'Device Status',
            subtitle: 'Notify about device status changes',
            value: _userPreferences.deviceStatusNotifications,
            icon: Icons.devices,
            onChanged: (value) {
              final updatedPreferences = _userPreferences.copyWith(
                deviceStatusNotifications: value,
              );
              setState(() {
                _userPreferences = updatedPreferences;
              });
              _updateUserPreferences(updatedPreferences);
            },
            indent: 24,
          ),
          _buildSwitchSetting(
            title: 'Weekly Reports',
            subtitle: 'Send weekly usage summary reports',
            value: _userPreferences.weeklyReportNotifications,
            icon: Icons.summarize,
            onChanged: (value) {
              final updatedPreferences = _userPreferences.copyWith(
                weeklyReportNotifications: value,
              );
              setState(() {
                _userPreferences = updatedPreferences;
              });
              _updateUserPreferences(updatedPreferences);
            },
            indent: 24,
          ),
          _buildSwitchSetting(
            title: 'Tips & Suggestions',
            subtitle: 'Receive energy-saving tips and suggestions',
            value: _userPreferences.tipsAndSuggestionsNotifications,
            icon: Icons.lightbulb,
            onChanged: (value) {
              final updatedPreferences = _userPreferences.copyWith(
                tipsAndSuggestionsNotifications: value,
              );
              setState(() {
                _userPreferences = updatedPreferences;
              });
              _updateUserPreferences(updatedPreferences);
            },
            indent: 24,
          ),
        ],

        const Divider(height: 32),

        // App appearance and behavior
        _buildSectionHeader('Appearance & Behavior'),
        _buildDarkModeToggleSetting(),
        _buildThemeSelectionSetting(), // Add the theme selection dropdown
        _buildSwitchSetting(
          title: 'Auto Update Data',
          subtitle: 'Automatically refresh device status',
          value: _userPreferences.autoUpdateEnabled,
          icon: Icons.sync,
          onChanged: (value) {
            final updatedPreferences = _userPreferences.copyWith(
              autoUpdateEnabled: value,
            );
            setState(() {
              _userPreferences = updatedPreferences;
            });
            _updateUserPreferences(updatedPreferences);
          },
        ),
      ],
    );
  }

  // Home Configuration Tab
  Widget _buildHomeConfigurationTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Basic home information
        _buildSectionHeader('Home Information'),
        _buildTextInputSetting(
          title: 'Home Name',
          subtitle: 'Give your home a name',
          value: _homeConfiguration.homeName,
          icon: Icons.home,
          onChanged: (value) {
            if (value.isNotEmpty) {
              final updatedConfig = _homeConfiguration.copyWith(
                homeName: value,
              );
              setState(() {
                _homeConfiguration = updatedConfig;
              });
              _updateHomeConfiguration(updatedConfig);
            }
          },
        ),
        _buildDropdownSetting<String>(
          title: 'Home Type',
          subtitle: 'Select your home type',
          value: _homeConfiguration.homeType,
          items: HomeConfiguration.availableHomeTypes,
          icon: Icons.house,
          onChanged: (value) {
            if (value != null) {
              final updatedConfig = _homeConfiguration.copyWith(
                homeType: value,
              );
              setState(() {
                _homeConfiguration = updatedConfig;
              });
              _updateHomeConfiguration(updatedConfig);
            }
          },
        ),
        _buildNumberInputSetting(
          title: 'Home Size',
          subtitle: 'Square feet/meters of your home',
          controller: _homeSizeController,
          icon: Icons.square_foot,
          onChanged: (value) {
            final size = double.tryParse(value);
            if (size != null) {
              final updatedConfig = _homeConfiguration.copyWith(homeSize: size);
              setState(() {
                _homeConfiguration = updatedConfig;
              });
              _updateHomeConfiguration(updatedConfig);
            }
          },
        ),
        _buildNumberInputSetting(
          title: 'Occupants',
          subtitle: 'Number of people living in your home',
          controller: _occupantsController,
          icon: Icons.people,
          onChanged: (value) {
            final occupants = int.tryParse(value);
            if (occupants != null) {
              final updatedConfig = _homeConfiguration.copyWith(
                occupants: occupants,
              );
              setState(() {
                _homeConfiguration = updatedConfig;
              });
              _updateHomeConfiguration(updatedConfig);
            }
          },
          isInteger: true,
        ),

        const Divider(height: 32),

        // Rooms section
        _buildSectionHeader(
          'Rooms',
          trailing: IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
            onPressed: () => _showAddRoomDialog(context),
          ),
        ),

        ..._homeConfiguration.rooms.map((room) => _buildRoomListItem(room)),

        if (_homeConfiguration.rooms.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('No rooms added yet. Tap the + icon to add rooms.'),
            ),
          ),

        const Divider(height: 32),

        // Energy goals section
        _buildSectionHeader('Energy Goals'),
        _buildNumberInputSetting(
          title: 'Monthly Energy Goal',
          subtitle: 'Target kWh per month',
          controller: _monthlyEnergyGoalController,
          icon: Icons.electric_bolt,
          onChanged: (value) {
            final goal = double.tryParse(value);
            if (goal != null) {
              final updatedConfig = _homeConfiguration.copyWith(
                monthlyEnergyGoal: goal,
              );
              setState(() {
                _homeConfiguration = updatedConfig;
              });
              _updateHomeConfiguration(updatedConfig);
            }
          },
        ),
        _buildNumberInputSetting(
          title: 'Monthly Cost Goal',
          subtitle: 'Target monthly energy cost',
          controller: _monthlyCostGoalController,
          icon: Icons.money,
          onChanged: (value) {
            final goal = double.tryParse(value);
            if (goal != null) {
              final updatedConfig = _homeConfiguration.copyWith(
                monthlyCostGoal: goal,
              );
              setState(() {
                _homeConfiguration = updatedConfig;
              });
              _updateHomeConfiguration(updatedConfig);
            }
          },
        ),

        const Divider(height: 32),

        // Utility provider information section
        _buildSectionHeader('Utility Provider Information (Optional)'),
        _buildTextInputSetting(
          title: 'Utility Provider',
          subtitle: 'Name of your energy company',
          value: _homeConfiguration.utilityProvider,
          icon: Icons.apartment,
          onChanged: (value) {
            final updatedConfig = _homeConfiguration.copyWith(
              utilityProvider: value,
            );
            setState(() {
              _homeConfiguration = updatedConfig;
            });
            _updateHomeConfiguration(updatedConfig);
          },
        ),
        _buildTextInputSetting(
          title: 'Account Number',
          subtitle: 'Your utility account number',
          value: _homeConfiguration.accountNumber,
          icon: Icons.numbers,
          onChanged: (value) {
            final updatedConfig = _homeConfiguration.copyWith(
              accountNumber: value,
            );
            setState(() {
              _homeConfiguration = updatedConfig;
            });
            _updateHomeConfiguration(updatedConfig);
          },
        ),
        _buildTextInputSetting(
          title: 'Utility Plan',
          subtitle: 'Your current utility plan or rate',
          value: _homeConfiguration.utilityPlan,
          icon: Icons.request_quote,
          onChanged: (value) {
            final updatedConfig = _homeConfiguration.copyWith(
              utilityPlan: value,
            );
            setState(() {
              _homeConfiguration = updatedConfig;
            });
            _updateHomeConfiguration(updatedConfig);
          },
        ),
        _buildTextInputSetting(
          title: 'Meter Number',
          subtitle: 'Your electricity meter number',
          value: _homeConfiguration.meterNumber,
          icon: Icons.speed,
          onChanged: (value) {
            final updatedConfig = _homeConfiguration.copyWith(
              meterNumber: value,
            );
            setState(() {
              _homeConfiguration = updatedConfig;
            });
            _updateHomeConfiguration(updatedConfig);
          },
        ),
      ],
    );
  }

  // Device Management Tab
  Widget _buildDeviceManagementTab() {
    // Get devices from AppState
    final appState = Provider.of<AppState>(context);
    final devices = appState.devices;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader(
          'Connected Devices',
          trailing: IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () {
              // Refresh devices list
              appState.scanForDevices();
            },
          ),
        ),

        // List of devices
        ...devices.map((device) {
          // Get device settings if they exist
          final deviceSettings = _deviceManagement.findDeviceSettingsById(
            device.id,
          );

          return _buildDeviceListItem(device: device, settings: deviceSettings);
        }), // Removed unnecessary .toList()

        if (devices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No devices connected. Go to the Devices tab to add devices.',
              ),
            ),
          ),

        // Help text
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Tap on a device to customize its settings, rename it, or assign it to a room.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // About & Help Tab
  Widget _buildAboutAndHelpTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // App information section
        _buildSectionHeader('App Information'),
        _buildInfoSetting(
          title: 'App Version',
          subtitle:
              '${_aboutSettings.appVersion} (Build ${_aboutSettings.buildNumber})',
          icon: Icons.info,
        ),
        _buildInfoSetting(
          title: 'Digital EcoHome Project',
          subtitle: 'A smart solution for home energy management',
          icon: Icons.eco,
        ),
        _buildButtonSetting( // Add button to navigate to AboutPage
          title: 'About Digital EcoHome',
          subtitle: 'View app information and team credits',
          icon: Icons.info_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutPage()),
            );
          },
        ),

       const Divider(height: 32),

       // Demo Mode section REMOVED

       // const Divider(height: 32), // Divider also removed

        // Tutorial section
        _buildSectionHeader('Tutorials'),
        _buildButtonSetting(
          title: 'App Tour',
          subtitle: 'Take a guided tour of the app features',
          icon: Icons.tour,
          onTap: () {
            _showTutorialDialog(context, 0);
          },
        ),
        _buildButtonSetting(
          title: 'Energy Monitoring Tutorial',
          subtitle: 'Learn how to monitor your energy usage',
          icon: Icons.show_chart,
          onTap: () {
            _showTutorialDialog(context, 1);
          },
        ),
        _buildButtonSetting(
          title: 'Setting Energy Goals',
          subtitle: 'Learn how to set and track energy goals',
          icon: Icons.track_changes,
          onTap: () {
            _showTutorialDialog(context, 2);
          },
        ),
        _buildButtonSetting(
          title: 'Energy Insights',
          subtitle: 'Understand energy usage insights and tips',
          icon: Icons.lightbulb,
          onTap: () {
            _showTutorialDialog(context, 3);
          },
        ),
        _buildButtonSetting(
          title: 'Device Control',
          subtitle: 'Learn how to control your smart devices',
          icon: Icons.devices,
          onTap: () {
            _showTutorialDialog(context, 4);
          },
        ),

        const Divider(height: 32),

        // FAQ section
        _buildSectionHeader('Frequently Asked Questions'),
        ..._aboutSettings.faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          return _buildFAQItem(faq, index);
        }), // Removed unnecessary .toList()

        const Divider(height: 32),

        // Support section
        _buildSectionHeader('Support'),
        _buildButtonSetting(
          title: 'Contact Support',
          subtitle: _aboutSettings.supportEmail,
          icon: Icons.email,
          onTap: () {
            // Open email client
          },
        ),
        _buildButtonSetting(
          title: 'Visit Website',
          subtitle: _aboutSettings.websiteUrl,
          icon: Icons.language,
          onTap: () {
            // Open website
          },
        ),
        _buildButtonSetting(
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          icon: Icons.privacy_tip,
          onTap: () {
            // Show privacy policy
          },
        ),
        _buildButtonSetting(
          title: 'Terms of Service',
          subtitle: 'View our terms and conditions',
          icon: Icons.description,
          onTap: () {
            // Show terms of service
          },
        ),
      ],
    );
  }

  // Advanced Settings Tab
  Widget _buildAdvancedSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Future IoT implementation notice
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Advanced Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'These settings are for future IoT implementation. Currently, they are display-only and will not affect app functionality.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        // Network settings section
        _buildSectionHeader('Network Settings'),
        _buildTextInputSetting(
          title: 'WiFi SSID',
          subtitle: 'Name of your WiFi network',
          value: _advancedSettings.networkSettings.wifiSSID,
          icon: Icons.wifi,
          onChanged: (value) {
            // This is for display only in this version
          },
          readOnly: true,
        ),
        _buildDropdownSetting<String>(
          title: 'WiFi Security Type',
          subtitle: 'Security protocol for your WiFi',
          value: _advancedSettings.networkSettings.wifiSecurityType,
          items: NetworkSettings.securityTypes,
          icon: Icons.security,
          onChanged: (value) {
            // This is for display only in this version
          },
          readOnly: true,
        ),
        _buildTextInputSetting(
          title: 'Hub IP Address',
          subtitle: 'IP address of your home IoT hub',
          value: _advancedSettings.networkSettings.hubIPAddress,
          icon: Icons.router,
          onChanged: (value) {
            // This is for display only in this version
          },
          readOnly: true,
        ),

        const Divider(height: 32),

        // Scan frequency options
        _buildSectionHeader('Scan Frequency'),
        _buildDropdownSetting<int>(
          title: 'Device Scan Interval',
          subtitle: 'How often to scan for new devices',
          value: _advancedSettings.scanFrequency.deviceScanIntervalMinutes,
          items: ScanFrequency.deviceScanIntervals,
          icon: Icons.devices,
          onChanged: (value) {
            // This is for display only in this version
          },
          formatItem: (item) => '$item minutes',
          readOnly: true,
        ),
        _buildDropdownSetting<int>(
          title: 'Power Usage Scan Interval',
          subtitle: 'How often to scan device power usage',
          value: _advancedSettings.scanFrequency.powerUsageScanIntervalSeconds,
          items: ScanFrequency.powerUsageScanIntervals,
          icon: Icons.electric_bolt,
          onChanged: (value) {
            // This is for display only in this version
          },
          formatItem: (item) => '$item seconds',
          readOnly: true,
        ),
        _buildDropdownSetting<int>(
          title: 'Energy Usage Update Interval',
          subtitle: 'How often to update energy usage stats',
          value:
              _advancedSettings.scanFrequency.energyUsageUpdateIntervalMinutes,
          items: ScanFrequency.energyUsageUpdateIntervals,
          icon: Icons.update,
          onChanged: (value) {
            // This is for display only in this version
          },
          formatItem: (item) => '$item minutes',
          readOnly: true,
        ),

        const Divider(height: 32),

        // Data storage preferences
        _buildSectionHeader('Data Storage'),
        _buildDropdownSetting<StorageLocation>(
          title: 'Storage Location',
          subtitle: 'Where to store usage history data',
          value:
              _advancedSettings.dataStoragePreferences.preferredStorageLocation,
          items: StorageLocation.values,
          icon: Icons.storage,
          onChanged: (value) {
            // This is for display only in this version
          },
          formatItem: (item) => item.name,
          readOnly: true,
        ),
        _buildDropdownSetting<int>(
          title: 'Data Retention Period',
          subtitle: 'How long to keep historical data',
          value: _advancedSettings.dataStoragePreferences.dataRetentionDays,
          items: DataStoragePreferences.dataRetentionPeriods,
          icon: Icons.history,
          onChanged: (value) {
            // This is for display only in this version
          },
          formatItem: (item) => '$item days',
          readOnly: true,
        ),
        _buildSwitchSetting(
          title: 'Compress Historical Data',
          subtitle: 'Save storage space by compressing old data',
          value:
              _advancedSettings.dataStoragePreferences.compressHistoricalData,
          icon: Icons.compress,
          onChanged: (value) {
            // This is for display only in this version
          },
          readOnly: true,
        ),

        const Divider(height: 32),

        // Hardware connection section
        _buildSectionHeader('Hardware Connection'),
        _buildDropdownSetting<String>(
          title: 'Controller Type',
          subtitle: 'Type of IoT controller',
          value: _advancedSettings.hardwareConnectionSettings.controllerType,
          items: HardwareConnectionSettings.controllerTypes,
          icon: Icons.developer_board,
          onChanged: (value) {
            // This is for display only in this version
          },
          readOnly: true,
        ),
        _buildTextInputSetting(
          title: 'Controller IP Address',
          subtitle: 'IP address of hardware controller',
          value:
              _advancedSettings.hardwareConnectionSettings.controllerIPAddress,
          icon: Icons.link,
          onChanged: (value) {
            // This is for display only in this version
          },
          readOnly: true,
        ),
        _buildInfoSetting(
          title: 'Connection Status',
          subtitle: 'Not Connected - Demo Mode',
          icon: Icons.info,
        ),

        const SizedBox(height: 32),

        // Reset button
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.restore, color: Colors.red),
            label: const Text(
              'Reset to Defaults',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Show confirmation dialog before resetting
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Reset Advanced Settings'),
                      content: const Text(
                        'This will reset all advanced settings to their default values. Are you sure you want to continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Reset advanced settings
                            setState(() {
                              _advancedSettings = AdvancedSettings();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper methods for device management
  Widget _buildDeviceListItem({
    required Device device,
    DeviceSettings? settings,
  }) {
    final customName =
        settings?.customName.isNotEmpty ?? false
            ? settings!.customName
            : device.name;

    // Get the room name if assigned
    String roomName = 'Unassigned';
    if (settings?.roomId != null) {
      final roomIndex = _homeConfiguration.rooms.indexWhere(
        (r) => r.id == settings!.roomId,
      );
      if (roomIndex != -1) {
        roomName = _homeConfiguration.rooms[roomIndex].name;
      }
    } else if (device.room != 'Unknown') {
      roomName = device.room;
    }

    // Get the priority label if set
    String priorityLabel = settings?.priority.name ?? 'Medium';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getIconForDevice(device), color: AppTheme.primaryColor),
        ),
        title: Text(
          customName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Room: $roomName'), Text('Priority: $priorityLabel')],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          setState(() {
            _editingDeviceId = device.id;
          });
          _showEditDeviceDialog(context, device, settings);
        },
      ),
    );
  }

  // Dialog to edit a device
  void _showEditDeviceDialog(
    BuildContext context,
    Device device,
    DeviceSettings? settings,
  ) {
    // Create temporary settings
    DeviceSettings tempSettings =
        settings ?? DeviceSettings(deviceId: device.id);

    // Controller for device name
    final nameController = TextEditingController(
      text:
          tempSettings.customName.isNotEmpty
              ? tempSettings.customName
              : device.name,
    );

    // Selected room ID
    String? selectedRoomId = tempSettings.roomId;

    // Selected priority
    DevicePriority selectedPriority = tempSettings.priority;

    // Auto turn off option
    bool autoTurnOff = tempSettings.autoTurnOff;

    // Auto turn off minutes controller
    final autoTurnOffController = TextEditingController(
      text: tempSettings.autoTurnOffMinutes?.toString() ?? '60',
    );

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Edit Device'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Device Name',
                          hintText: 'Enter a custom name for this device',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Room selection
                      const Text(
                        'Assign to Room',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<String?>(
                        value: selectedRoomId,
                        decoration: const InputDecoration(
                          hintText: 'Select a room',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Unassigned'),
                          ),
                          ..._homeConfiguration.rooms.map((room) {
                            return DropdownMenuItem<String?>(
                              value: room.id,
                              child: Text(room.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRoomId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Priority selection
                      const Text(
                        'Device Priority',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<DevicePriority>(
                        value: selectedPriority,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items:
                            DevicePriority.values.map((priority) {
                              return DropdownMenuItem<DevicePriority>(
                                value: priority,
                                child: Text(
                                  '${priority.name} - ${priority.description}',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Auto turn off option
                      Row(
                        children: [
                          Checkbox(
                            value: autoTurnOff,
                            onChanged: (value) {
                              setState(() {
                                autoTurnOff = value ?? false;
                              });
                            },
                          ),
                          const Text('Auto turn off after inactivity'),
                        ],
                      ),

                      // Show minutes field if auto turn off is enabled
                      if (autoTurnOff)
                        TextField(
                          controller: autoTurnOffController,
                          decoration: const InputDecoration(
                            labelText: 'Minutes',
                            hintText: 'Enter minutes of inactivity',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Update device settings
                      final minutes = int.tryParse(autoTurnOffController.text);

                      final updatedSettings = DeviceSettings(
                        deviceId: device.id,
                        customName: nameController.text,
                        roomId: selectedRoomId,
                        priority: selectedPriority,
                        autoTurnOff: autoTurnOff,
                        autoTurnOffMinutes: autoTurnOff ? minutes : null,
                      );

                      // Update local device management
                      setState(() {
                        _deviceManagement.updateDeviceSettings(updatedSettings);
                      });

                      // Update app state
                      _updateDeviceManagement(_deviceManagement);

                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Room list item
  Widget _buildRoomListItem(Room room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getIconForRoom(room), color: AppTheme.primaryColor),
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditRoomDialog(context, room),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _showDeleteRoomConfirmation(context, room),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to add a new room
  void _showAddRoomDialog(BuildContext context) {
    _newRoomNameController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Room'),
            content: TextField(
              controller: _newRoomNameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter a name for the room',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_newRoomNameController.text.isNotEmpty) {
                    // Generate a unique ID
                    final id = 'room_${DateTime.now().millisecondsSinceEpoch}';

                    // Create a new room
                    final newRoom = Room(
                      id: id,
                      name: _newRoomNameController.text,
                    );

                    // Add room to local configuration
                    setState(() {
                      _homeConfiguration.addRoom(newRoom);
                    });

                    // Update app state
                    _updateHomeConfiguration(_homeConfiguration);

                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  // Dialog to edit a room
  void _showEditRoomDialog(BuildContext context, Room room) {
    final nameController = TextEditingController(text: room.name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Room'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter a name for the room',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    // Create an updated room
                    final updatedRoom = room.copyWith(
                      name: nameController.text,
                    );

                    // Update room in local configuration
                    setState(() {
                      _homeConfiguration.updateRoom(updatedRoom);
                    });

                    // Update app state
                    _updateHomeConfiguration(_homeConfiguration);

                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  // Confirmation dialog to delete a room
  void _showDeleteRoomConfirmation(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Room'),
            content: Text(
              'Are you sure you want to delete "${room.name}"? This will unassign all devices from this room.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Remove room from local configuration
                  setState(() {
                    _homeConfiguration.removeRoom(room.id);

                    // Also update device assignments
                    for (
                      var i = 0;
                      i < _deviceManagement.deviceSettings.length;
                      i++
                    ) {
                      if (_deviceManagement.deviceSettings[i].roomId ==
                          room.id) {
                        _deviceManagement.deviceSettings[i] = _deviceManagement
                            .deviceSettings[i]
                            .copyWith(roomId: null);
                      }
                    }
                  });

                  // Update app state
                  _updateHomeConfiguration(_homeConfiguration);
                  _updateDeviceManagement(_deviceManagement);

                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // Show FAQ item with expandable content
  Widget _buildFAQItem(FAQItem faq, int index) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      tilePadding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(faq.answer),
        ),
      ],
    );
  }

  // Display tutorial dialog
  void _showTutorialDialog(BuildContext context, int initialIndex) {
    final PageController pageController = PageController(
      initialPage: initialIndex,
    );

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      children:
                          _aboutSettings.tutorialScreens.map((tutorial) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tutorial.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tutorial.description,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Common UI elements

  // Section header
  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Switch setting
  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    double indent = 0,
    bool readOnly = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0, left: indent),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
        ),
        trailing: Switch(
          value: value,
          onChanged: readOnly ? null : onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  // Dropdown setting
  Widget _buildDropdownSetting<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    String Function(T)? formatItem,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
        ),
        trailing: DropdownButton<T>(
          value: value,
          items:
              items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(formatItem != null ? formatItem(item) : '$item'),
                );
              }).toList(),
          onChanged: readOnly ? null : onChanged,
          underline: const SizedBox(),
        ),
      ),
    );
  }

  // Number input setting
  Widget _buildNumberInputSetting({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required IconData icon,
    bool isInteger = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
        ),
        trailing: SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType:
                isInteger
                    ? TextInputType.number
                    : const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            readOnly: readOnly,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: readOnly ? null : onChanged,
          ),
        ),
      ),
    );
  }

  // Text input setting
  Widget _buildTextInputSetting({
    required String title,
    required String subtitle,
    required String value,
    required ValueChanged<String> onChanged,
    required IconData icon,
    bool readOnly = false,
  }) {
    // Create a controller for this setting
    final controller = TextEditingController(text: value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              readOnly: readOnly,
              onChanged: readOnly ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }

  // Info setting (non-editable)
  Widget _buildInfoSetting({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
      ),
    );
  }

  // Button setting
  Widget _buildButtonSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Helper methods

  // Get icon for device type
  IconData _getIconForDevice(Device device) {
    switch (device.type) {
      case 'HVAC':
        return Icons.ac_unit;
      case 'Appliance':
        return Icons.kitchen;
      case 'Light':
        return Icons.lightbulb;
      case 'Water':
        return Icons.water_drop;
      default:
        return Icons.devices;
    }
  }

  // Get icon for room type
  IconData _getIconForRoom(Room room) {
    // In a real app, you might store icon information with the room
    // For now, use a simple mapping based on room name
    final name = room.name.toLowerCase();

    if (name.contains('living')) return Icons.weekend;
    if (name.contains('kitchen')) return Icons.kitchen;
    if (name.contains('bedroom')) return Icons.bed;
    if (name.contains('bathroom')) return Icons.bathtub;
    if (name.contains('office')) return Icons.computer;
    if (name.contains('garage')) return Icons.garage;
    if (name.contains('basement')) return Icons.foundation;

    return Icons.door_front_door;
  }

  // Update methods

  void _updateUserPreferences(UserPreferences preferences) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateUserPreferences(preferences);
  }

  void _updateHomeConfiguration(HomeConfiguration configuration) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateHomeConfiguration(configuration);
  }

  void _updateDeviceManagement(DeviceManagement management) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateDeviceManagement(management);
  }

  // Removed unused method _updateAdvancedSettings

  // Custom dark mode toggle setting
  Widget _buildDarkModeToggleSetting() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.dark_mode, color: AppTheme.primaryColor),
        ),
        title: Text(
          'Dark Mode',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Text(
          'Toggle dark theme',
          style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
        ),
        trailing: DarkModeToggle(
          value: _userPreferences.darkModeEnabled,
          onChanged: (value) {
            // Update user preferences
            final updatedPreferences = _userPreferences.copyWith(
              darkModeEnabled: value,
            );
            setState(() {
              _userPreferences = updatedPreferences;
            });
            _updateUserPreferences(updatedPreferences);

            // Update theme provider
            themeProvider.setDarkMode(value);
          },
        ),
      ),
    );
  }


  // Theme selection setting
  Widget _buildThemeSelectionSetting() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return _buildDropdownSetting<String>(
      title: 'App Theme',
      subtitle: 'Select the application theme',
      value: themeProvider.selectedThemeKey,
      items: themeProvider.availableThemeKeys,
      icon: Icons.palette,
      onChanged: (value) {
        if (value != null) {
          themeProvider.setTheme(value);
          // Optionally, update user preferences if theme is stored there too
          // final updatedPreferences = _userPreferences.copyWith(selectedTheme: value);
          // setState(() { _userPreferences = updatedPreferences; });
          // _updateUserPreferences(updatedPreferences);
        }
      },
    );
  }

}
