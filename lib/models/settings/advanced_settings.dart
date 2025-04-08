// File: advanced_settings.dart
// Contains advanced settings for the Digital EcoHome app's future IoT implementation

class AdvancedSettings {
  // Network settings
  NetworkSettings networkSettings;

  // Scan frequency settings
  ScanFrequency scanFrequency;

  // Data storage preferences
  DataStoragePreferences dataStoragePreferences;

  // Hardware connection settings
  HardwareConnectionSettings hardwareConnectionSettings;

  // Default constructor with initial values
  AdvancedSettings({
    NetworkSettings? networkSettings,
    ScanFrequency? scanFrequency,
    DataStoragePreferences? dataStoragePreferences,
    HardwareConnectionSettings? hardwareConnectionSettings,
  }) : this.networkSettings = networkSettings ?? NetworkSettings(),
       this.scanFrequency = scanFrequency ?? ScanFrequency(),
       this.dataStoragePreferences =
           dataStoragePreferences ?? DataStoragePreferences(),
       this.hardwareConnectionSettings =
           hardwareConnectionSettings ?? HardwareConnectionSettings();

  // Create a copy with modified values
  AdvancedSettings copyWith({
    NetworkSettings? networkSettings,
    ScanFrequency? scanFrequency,
    DataStoragePreferences? dataStoragePreferences,
    HardwareConnectionSettings? hardwareConnectionSettings,
  }) {
    return AdvancedSettings(
      networkSettings: networkSettings ?? this.networkSettings,
      scanFrequency: scanFrequency ?? this.scanFrequency,
      dataStoragePreferences:
          dataStoragePreferences ?? this.dataStoragePreferences,
      hardwareConnectionSettings:
          hardwareConnectionSettings ?? this.hardwareConnectionSettings,
    );
  }
}

// Network settings for IoT device connections
class NetworkSettings {
  String wifiSSID;
  String wifiSecurityType;
  String hubIPAddress;
  int hubPort;
  bool useDHCP;
  String staticIPAddress;
  String subnetMask;
  String defaultGateway;
  String primaryDNS;
  String secondaryDNS;

  // Default constructor with initial values
  NetworkSettings({
    this.wifiSSID = '',
    this.wifiSecurityType = 'WPA2',
    this.hubIPAddress = '192.168.1.100',
    this.hubPort = 8080,
    this.useDHCP = true,
    this.staticIPAddress = '192.168.1.200',
    this.subnetMask = '255.255.255.0',
    this.defaultGateway = '192.168.1.1',
    this.primaryDNS = '8.8.8.8',
    this.secondaryDNS = '8.8.4.4',
  });

  // Available WiFi security types
  static List<String> get securityTypes => [
    'WPA2',
    'WPA3',
    'WPA/WPA2',
    'WEP',
    'None',
  ];
}

// Scan frequency settings
class ScanFrequency {
  int deviceScanIntervalMinutes;
  int powerUsageScanIntervalSeconds;
  int energyUsageUpdateIntervalMinutes;
  bool automaticScanning;

  // Default constructor with initial values
  ScanFrequency({
    this.deviceScanIntervalMinutes = 15,
    this.powerUsageScanIntervalSeconds = 30,
    this.energyUsageUpdateIntervalMinutes = 5,
    this.automaticScanning = true,
  });

  // Available scan intervals in minutes
  static List<int> get deviceScanIntervals => [5, 10, 15, 30, 60];

  // Available power usage scan intervals in seconds
  static List<int> get powerUsageScanIntervals => [10, 15, 30, 60, 120];

  // Available energy usage update intervals in minutes
  static List<int> get energyUsageUpdateIntervals => [1, 5, 15, 30, 60];
}

// Data storage preferences
class DataStoragePreferences {
  StorageLocation preferredStorageLocation;
  int dataRetentionDays;
  bool compressHistoricalData;
  bool autoBackupEnabled;
  int autoBackupIntervalDays;
  String backupLocation;

  // Default constructor with initial values
  DataStoragePreferences({
    this.preferredStorageLocation = StorageLocation.local,
    this.dataRetentionDays = 90,
    this.compressHistoricalData = true,
    this.autoBackupEnabled = false,
    this.autoBackupIntervalDays = 7,
    this.backupLocation = '',
  });

  // Available data retention periods in days
  static List<int> get dataRetentionPeriods => [30, 60, 90, 180, 365, 730];

  // Available auto backup intervals in days
  static List<int> get autoBackupIntervals => [1, 3, 7, 14, 30];
}

// Storage location enum
enum StorageLocation { local, cloud, both }

// Convert StorageLocation to user-friendly string
extension StorageLocationExtension on StorageLocation {
  String get name {
    switch (this) {
      case StorageLocation.local:
        return 'Local Storage';
      case StorageLocation.cloud:
        return 'Cloud Storage';
      case StorageLocation.both:
        return 'Local & Cloud';
    }
  }
}

// Hardware connection settings
class HardwareConnectionSettings {
  String controllerType;
  String controllerIPAddress;
  int controllerPort;
  String apiKey;
  String apiSecret;
  List<String> connectedHardwareIds;

  // Default constructor with initial values
  HardwareConnectionSettings({
    this.controllerType = 'Arduino Hub',
    this.controllerIPAddress = '192.168.1.150',
    this.controllerPort = 80,
    this.apiKey = '',
    this.apiSecret = '',
    List<String>? connectedHardwareIds,
  }) : this.connectedHardwareIds = connectedHardwareIds ?? [];

  // Available controller types
  static List<String> get controllerTypes => [
    'Arduino Hub',
    'Raspberry Pi',
    'ESP32',
    'Custom',
  ];
}
