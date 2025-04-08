// File: device_management.dart
// Contains device management settings for the Digital EcoHome app

class DeviceManagement {
  // List of device settings (different from the actual Device instances)
  List<DeviceSettings> deviceSettings;

  // Default constructor
  DeviceManagement({List<DeviceSettings>? deviceSettings})
    : this.deviceSettings = deviceSettings ?? [];

  // Find device settings by device id
  DeviceSettings? findDeviceSettingsById(String deviceId) {
    final index = deviceSettings.indexWhere(
      (settings) => settings.deviceId == deviceId,
    );
    return index != -1 ? deviceSettings[index] : null;
  }

  // Add or update device settings
  void updateDeviceSettings(DeviceSettings settings) {
    final index = deviceSettings.indexWhere(
      (s) => s.deviceId == settings.deviceId,
    );
    if (index != -1) {
      deviceSettings[index] = settings;
    } else {
      deviceSettings.add(settings);
    }
  }

  // Remove device settings
  void removeDeviceSettings(String deviceId) {
    deviceSettings.removeWhere((settings) => settings.deviceId == deviceId);
  }

  // Get devices by room
  List<DeviceSettings> getDevicesByRoom(String roomId) {
    return deviceSettings
        .where((settings) => settings.roomId == roomId)
        .toList();
  }

  // Get high priority devices
  List<DeviceSettings> getHighPriorityDevices() {
    return deviceSettings
        .where((settings) => settings.priority == DevicePriority.high)
        .toList();
  }
}

// Device settings for a single device
class DeviceSettings {
  final String deviceId;
  String customName;
  String? roomId;
  DevicePriority priority;
  bool autoTurnOff;
  int? autoTurnOffMinutes;

  // Default constructor with initial values
  DeviceSettings({
    required this.deviceId,
    this.customName = '',
    this.roomId,
    this.priority = DevicePriority.medium,
    this.autoTurnOff = false,
    this.autoTurnOffMinutes,
  });

  // Create a copy with modified values
  DeviceSettings copyWith({
    String? customName,
    String? roomId,
    DevicePriority? priority,
    bool? autoTurnOff,
    int? autoTurnOffMinutes,
  }) {
    return DeviceSettings(
      deviceId: this.deviceId,
      customName: customName ?? this.customName,
      roomId: roomId ?? this.roomId,
      priority: priority ?? this.priority,
      autoTurnOff: autoTurnOff ?? this.autoTurnOff,
      autoTurnOffMinutes: autoTurnOffMinutes ?? this.autoTurnOffMinutes,
    );
  }
}

// Device priority enum
enum DevicePriority {
  low, // Non-essential devices that can be turned off anytime
  medium, // Standard priority for most devices
  high, // Critical devices that should stay on (medical, security)
}

// Convert DevicePriority to user-friendly string
extension DevicePriorityExtension on DevicePriority {
  String get name {
    switch (this) {
      case DevicePriority.low:
        return 'Low';
      case DevicePriority.medium:
        return 'Medium';
      case DevicePriority.high:
        return 'High';
    }
  }

  String get description {
    switch (this) {
      case DevicePriority.low:
        return 'Non-essential devices that can be turned off anytime';
      case DevicePriority.medium:
        return 'Standard priority for most devices';
      case DevicePriority.high:
        return 'Critical devices that should stay on (medical, security)';
    }
  }
}
