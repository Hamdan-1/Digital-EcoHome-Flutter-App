// This file contains extensions to the AppState class to support demo mode functionality

import 'package:flutter/material.dart';
import 'app_state.dart';
import 'demo_mode.dart';

extension DemoModeSupport on AppState {
  // For storing demo data (since we can't access private fields)
  static final Map<String, dynamic> _demoData = {};

  // Method to update app state with demo data
  void updateWithDemoData({
    required List<Device> demoDevices,
    required List<double> demoHourlyUsage,
    required List<EnergyAlert> demoAlerts,
    double? demoPowerUsage,
    double? demoTodayUsage,
    double? demoWeeklyUsage,
    double? demoMonthlyUsage,
  }) {
    // Store the original values for later restoration
    if (!_demoData.containsKey('originalDevices')) {
      _demoData['originalDevices'] = List<Device>.from(devices);
      _demoData['originalHourlyUsage'] = List<double>.from(hourlyUsageData);
      _demoData['originalAlerts'] = List<EnergyAlert>.from(energyAlerts);
      _demoData['originalTodayUsage'] = todayUsage;
      _demoData['originalWeeklyUsage'] = weeklyUsage;
      _demoData['originalMonthlyUsage'] = monthlyUsage;
      _demoData['originalPowerUsage'] = currentPowerUsage;
    }

    // Store current demo data
    _demoData['demoDevices'] = demoDevices;
    _demoData['demoHourlyUsage'] = demoHourlyUsage;
    _demoData['demoAlerts'] = demoAlerts;

    // Update app state through internal implementation
    updateDemoState(
      demoDevices: demoDevices,
      demoHourlyUsage: demoHourlyUsage,
      demoAlerts: demoAlerts,
      demoPowerUsage: demoPowerUsage,
      demoTodayUsage: demoTodayUsage,
      demoWeeklyUsage: demoWeeklyUsage,
      demoMonthlyUsage: demoMonthlyUsage,
    );

    // Notify listeners of changes
    notifyListeners();
  }

  // Method to restore original app state after demo
  void restoreFromBackup() {
    // Check if we have backup data to restore
    if (_demoData.containsKey('originalDevices')) {
      // Restore original data using the internal implementation
      updateDemoState(
        demoDevices: _demoData['originalDevices'],
        demoHourlyUsage: _demoData['originalHourlyUsage'],
        demoAlerts: _demoData['originalAlerts'],
        demoPowerUsage: _demoData['originalPowerUsage'],
        demoTodayUsage: _demoData['originalTodayUsage'],
        demoWeeklyUsage: _demoData['originalWeeklyUsage'],
        demoMonthlyUsage: _demoData['originalMonthlyUsage'],
      );

      // Clear stored demo data
      _demoData.clear();

      // Notify listeners of changes
      notifyListeners();
    }
  }

  // Internal method to update the app state for demo mode
  // This method should be implemented in the AppState class
  void updateDemoState({
    List<Device>? demoDevices,
    List<double>? demoHourlyUsage,
    List<EnergyAlert>? demoAlerts,
    double? demoPowerUsage,
    double? demoTodayUsage,
    double? demoWeeklyUsage,
    double? demoMonthlyUsage,
  }) {
    // This is a placeholder method that should be implemented in the AppState class
    // The implementation will depend on how the AppState manages its internal state

    // For now, we'll add a dummy implementation that does nothing
    // This must be properly implemented in the AppState class to make demo mode work
  }
}
