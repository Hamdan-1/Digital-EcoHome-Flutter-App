import 'package:flutter/material.dart';

class EnergyReportData {
  final DateTime date;
  final double energyUsage;
  final Map<String, double> deviceCategoryBreakdown;
  final Map<String, double> deviceBreakdown;
  final double cost;
  final double co2Emissions;

  EnergyReportData({
    required this.date,
    required this.energyUsage,
    required this.deviceCategoryBreakdown,
    required this.deviceBreakdown,
    required this.cost,
    required this.co2Emissions,
  });

  static List<EnergyReportData> generateDailyData() {
    // Generate data for the last 30 days
    final List<EnergyReportData> data = [];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final baseUsage =
          10.0 + (date.weekday >= 6 ? 4.0 : 0.0); // More usage on weekends
      final variance = (date.day % 5) * 0.8; // Add some variance

      // Create the report
      data.add(
        EnergyReportData(
          date: date,
          energyUsage: baseUsage + variance,
          deviceCategoryBreakdown: {
            'HVAC': (baseUsage + variance) * 0.45,
            'Appliance': (baseUsage + variance) * 0.25,
            'Light': (baseUsage + variance) * 0.15,
            'Water': (baseUsage + variance) * 0.10,
            'Other': (baseUsage + variance) * 0.05,
          },
          deviceBreakdown: {
            'Air Conditioner': (baseUsage + variance) * 0.35,
            'Refrigerator': (baseUsage + variance) * 0.12,
            'Washing Machine': (baseUsage + variance) * 0.08,
            'Living Room Lights': (baseUsage + variance) * 0.08,
            'Water Heater': (baseUsage + variance) * 0.10,
            'Kitchen Lights': (baseUsage + variance) * 0.06,
            'TV': (baseUsage + variance) * 0.05,
            'Microwave': (baseUsage + variance) * 0.06,
            'Dishwasher': (baseUsage + variance) * 0.05,
            'Other': (baseUsage + variance) * 0.05,
          },
          cost: (baseUsage + variance) * 0.15, // $0.15 per kWh
          co2Emissions: (baseUsage + variance) * 0.85, // 0.85 kg CO2 per kWh
        ),
      );
    }

    return data;
  }

  static List<EnergyReportData> generateWeeklyData() {
    // Generate data for the last 12 weeks
    final List<EnergyReportData> data = [];
    final now = DateTime.now();

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - (i * 7));
      final baseUsage = 70.0 + (i % 4) * 5.0; // Seasonal variations
      final variance = (date.month % 3) * 3.0; // Monthly variance

      data.add(
        EnergyReportData(
          date: date,
          energyUsage: baseUsage + variance,
          deviceCategoryBreakdown: {
            'HVAC': (baseUsage + variance) * 0.45,
            'Appliance': (baseUsage + variance) * 0.25,
            'Light': (baseUsage + variance) * 0.15,
            'Water': (baseUsage + variance) * 0.10,
            'Other': (baseUsage + variance) * 0.05,
          },
          deviceBreakdown: {
            'Air Conditioner': (baseUsage + variance) * 0.35,
            'Refrigerator': (baseUsage + variance) * 0.12,
            'Washing Machine': (baseUsage + variance) * 0.08,
            'Living Room Lights': (baseUsage + variance) * 0.08,
            'Water Heater': (baseUsage + variance) * 0.10,
            'Kitchen Lights': (baseUsage + variance) * 0.06,
            'TV': (baseUsage + variance) * 0.05,
            'Microwave': (baseUsage + variance) * 0.06,
            'Dishwasher': (baseUsage + variance) * 0.05,
            'Other': (baseUsage + variance) * 0.05,
          },
          cost: (baseUsage + variance) * 0.15, // $0.15 per kWh
          co2Emissions: (baseUsage + variance) * 0.85, // 0.85 kg CO2 per kWh
        ),
      );
    }

    return data;
  }

  static List<EnergyReportData> generateMonthlyData() {
    // Generate data for the last 12 months
    final List<EnergyReportData> data = [];
    final now = DateTime.now();

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);

      // Seasonal patterns: higher usage in summer (month 6-8) and winter (month 12, 1-2)
      double baseUsage = 300.0;
      if (date.month >= 6 && date.month <= 8) {
        baseUsage += 50.0; // Summer
      } else if (date.month == 12 || date.month <= 2) {
        baseUsage += 60.0; // Winter
      }

      final variance = (date.month % 4) * 10.0;

      data.add(
        EnergyReportData(
          date: date,
          energyUsage: baseUsage + variance,
          deviceCategoryBreakdown: {
            'HVAC': (baseUsage + variance) * 0.45,
            'Appliance': (baseUsage + variance) * 0.25,
            'Light': (baseUsage + variance) * 0.15,
            'Water': (baseUsage + variance) * 0.10,
            'Other': (baseUsage + variance) * 0.05,
          },
          deviceBreakdown: {
            'Air Conditioner': (baseUsage + variance) * 0.35,
            'Refrigerator': (baseUsage + variance) * 0.12,
            'Washing Machine': (baseUsage + variance) * 0.08,
            'Living Room Lights': (baseUsage + variance) * 0.08,
            'Water Heater': (baseUsage + variance) * 0.10,
            'Kitchen Lights': (baseUsage + variance) * 0.06,
            'TV': (baseUsage + variance) * 0.05,
            'Microwave': (baseUsage + variance) * 0.06,
            'Dishwasher': (baseUsage + variance) * 0.05,
            'Other': (baseUsage + variance) * 0.05,
          },
          cost: (baseUsage + variance) * 0.15, // $0.15 per kWh
          co2Emissions: (baseUsage + variance) * 0.85, // 0.85 kg CO2 per kWh
        ),
      );
    }

    return data;
  }

  static List<EnergyReportData> generateYearlyData() {
    // Generate data for the last 5 years
    final List<EnergyReportData> data = [];
    final now = DateTime.now();

    for (int i = 4; i >= 0; i--) {
      final date = DateTime(now.year - i, 1, 1);
      final baseUsage = 3500.0 + (i % 3) * 200.0; // Yearly variations
      final variance = (date.year % 3) * 100.0;

      data.add(
        EnergyReportData(
          date: date,
          energyUsage: baseUsage + variance,
          deviceCategoryBreakdown: {
            'HVAC': (baseUsage + variance) * 0.45,
            'Appliance': (baseUsage + variance) * 0.25,
            'Light': (baseUsage + variance) * 0.15,
            'Water': (baseUsage + variance) * 0.10,
            'Other': (baseUsage + variance) * 0.05,
          },
          deviceBreakdown: {
            'Air Conditioner': (baseUsage + variance) * 0.35,
            'Refrigerator': (baseUsage + variance) * 0.12,
            'Washing Machine': (baseUsage + variance) * 0.08,
            'Living Room Lights': (baseUsage + variance) * 0.08,
            'Water Heater': (baseUsage + variance) * 0.10,
            'Kitchen Lights': (baseUsage + variance) * 0.06,
            'TV': (baseUsage + variance) * 0.05,
            'Microwave': (baseUsage + variance) * 0.06,
            'Dishwasher': (baseUsage + variance) * 0.05,
            'Other': (baseUsage + variance) * 0.05,
          },
          cost: (baseUsage + variance) * 0.15, // $0.15 per kWh
          co2Emissions: (baseUsage + variance) * 0.85, // 0.85 kg CO2 per kWh
        ),
      );
    }

    return data;
  }
}

class EnergySavingTip {
  final String title;
  final String description;
  final IconData icon;
  final double potentialSavings;

  EnergySavingTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.potentialSavings,
  });

  static List<EnergySavingTip> generateTips() {
    return [
      EnergySavingTip(
        title: 'Optimize Thermostat',
        description:
            'Adjusting your thermostat by 1°F could save up to 3% on your heating/cooling costs. Consider setting it to 78°F in summer and 68°F in winter.',
        icon: Icons.thermostat,
        potentialSavings: 45.0,
      ),
      EnergySavingTip(
        title: 'LED Lighting Upgrade',
        description:
            'Replace remaining incandescent bulbs with LEDs to use up to 75% less energy and last 25 times longer.',
        icon: Icons.lightbulb,
        potentialSavings: 28.0,
      ),
      EnergySavingTip(
        title: 'Smart Power Strips',
        description:
            'Use smart power strips to eliminate phantom energy use from devices on standby mode.',
        icon: Icons.power,
        potentialSavings: 35.0,
      ),
      EnergySavingTip(
        title: 'Washing Machine Efficiency',
        description:
            'Wash clothes in cold water whenever possible and run full loads to maximize efficiency.',
        icon: Icons.local_laundry_service,
        potentialSavings: 22.0,
      ),
      EnergySavingTip(
        title: 'HVAC Maintenance',
        description:
            'Schedule regular maintenance for your HVAC system and replace filters monthly to ensure optimal efficiency.',
        icon: Icons.hvac,
        potentialSavings: 52.0,
      ),
    ];
  }
}

class EnergyAlert {
  final String title;
  final String description;
  final DateTime time;
  final IconData icon;
  final bool isImportant;

  EnergyAlert({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.isImportant,
  });

  static List<EnergyAlert> generateAlerts() {
    final now = DateTime.now();

    return [
      EnergyAlert(
        title: 'Unusual Energy Spike',
        description:
            'An unusual energy spike was detected in your Air Conditioner at 2 PM today.',
        time: now.subtract(const Duration(hours: 3)),
        icon: Icons.warning_amber,
        isImportant: true,
      ),
      EnergyAlert(
        title: 'Device Left On',
        description:
            'Your Living Room Lights have been on for more than 12 hours.',
        time: now.subtract(const Duration(hours: 1)),
        icon: Icons.lightbulb,
        isImportant: false,
      ),
      EnergyAlert(
        title: 'High HVAC Usage',
        description: 'Your HVAC system is running 40% more than usual today.',
        time: now.subtract(const Duration(hours: 5)),
        icon: Icons.thermostat,
        isImportant: true,
      ),
      EnergyAlert(
        title: 'Peak Usage Hours',
        description:
            'Energy rates are higher between 5-8 PM. Consider reducing usage during this time.',
        time: now.subtract(const Duration(hours: 10)),
        icon: Icons.access_time,
        isImportant: false,
      ),
    ];
  }
}

class DeviceEnergyInfo {
  final String name;
  final String type;
  final double dailyUsage;
  final double weeklyCost;
  final double monthlyUsage;
  final String iconPath;
  final Color color;

  DeviceEnergyInfo({
    required this.name,
    required this.type,
    required this.dailyUsage,
    required this.weeklyCost,
    required this.monthlyUsage,
    required this.iconPath,
    required this.color,
  });

  static List<DeviceEnergyInfo> generateDeviceList() {
    return [
      DeviceEnergyInfo(
        name: 'Air Conditioner',
        type: 'HVAC',
        dailyUsage: 5.2,
        weeklyCost: 5.46,
        monthlyUsage: 156.0,
        iconPath: 'ac_unit',
        color: Colors.blue,
      ),
      DeviceEnergyInfo(
        name: 'Refrigerator',
        type: 'Appliance',
        dailyUsage: 1.8,
        weeklyCost: 1.89,
        monthlyUsage: 54.0,
        iconPath: 'kitchen',
        color: Colors.green,
      ),
      DeviceEnergyInfo(
        name: 'Water Heater',
        type: 'Water',
        dailyUsage: 1.5,
        weeklyCost: 1.58,
        monthlyUsage: 45.0,
        iconPath: 'hot_tub',
        color: Colors.red,
      ),
      DeviceEnergyInfo(
        name: 'Washing Machine',
        type: 'Appliance',
        dailyUsage: 0.8,
        weeklyCost: 0.84,
        monthlyUsage: 24.0,
        iconPath: 'local_laundry_service',
        color: Colors.purple,
      ),
      DeviceEnergyInfo(
        name: 'Living Room Lights',
        type: 'Light',
        dailyUsage: 0.6,
        weeklyCost: 0.63,
        monthlyUsage: 18.0,
        iconPath: 'lightbulb',
        color: Colors.amber,
      ),
      DeviceEnergyInfo(
        name: 'TV',
        type: 'Entertainment',
        dailyUsage: 0.5,
        weeklyCost: 0.53,
        monthlyUsage: 15.0,
        iconPath: 'tv',
        color: Colors.indigo,
      ),
      DeviceEnergyInfo(
        name: 'Kitchen Lights',
        type: 'Light',
        dailyUsage: 0.4,
        weeklyCost: 0.42,
        monthlyUsage: 12.0,
        iconPath: 'lightbulb',
        color: Colors.amber.shade700,
      ),
      DeviceEnergyInfo(
        name: 'Microwave',
        type: 'Appliance',
        dailyUsage: 0.2,
        weeklyCost: 0.21,
        monthlyUsage: 6.0,
        iconPath: 'microwave',
        color: Colors.grey,
      ),
    ];
  }
}
