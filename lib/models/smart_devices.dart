// Base device class - assuming this exists in your app_state.dart or elsewhere
// This is a simplified version to support our new device types
abstract class Device {
  final String id;
  final String name;
  final String type;
  final String model;
  final String room;
  final String iconPath;
  final bool isOn;
  final bool isActive;
  final double currentUsage;
  final Map<String, dynamic>? settings;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.model,
    required this.room,
    required this.iconPath,
    required this.isOn,
    required this.isActive,
    required this.currentUsage,
    this.settings,
  });
}

class SmartWaterHeater extends Device {
  SmartWaterHeater({
    required super.id,
    required super.name,
    required super.model,
    required super.room,
    required super.isOn,
    required super.isActive,
    required super.currentUsage,
    Map<String, dynamic>? settings,
  }) : super(
          type: 'Appliance',
          iconPath: 'hot_tub',
          settings: settings ?? {
            'temperature': 120,
            'mode': 'Normal',
            'timerHours': 0,
          },
        );
}

class SmartRefrigerator extends Device {
  SmartRefrigerator({
    required super.id,
    required super.name,
    required super.model,
    required super.room,
    required super.isOn,
    required super.isActive,
    required super.currentUsage,
    Map<String, dynamic>? settings,
  }) : super(
          type: 'Appliance',
          iconPath: 'kitchen',
          settings: settings ?? {
            'fridgeTemperature': 37,
            'freezerTemperature': 0,
            'mode': 'Normal',
            'quickCool': false,
            'quickFreeze': false,
          },
        );
}
