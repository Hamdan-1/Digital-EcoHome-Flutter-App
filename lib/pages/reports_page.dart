import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Unused import
import 'package:intl/intl.dart';
// import '../models/app_state.dart' hide EnergyAlert; // Unused import
import '../theme.dart';
// import '../widgets/usage_chart.dart'; // Unused import
import '../widgets/report_charts.dart';
import '../models/reports/energy_report_model.dart';
// Removed Demo Mode import

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  final List<String> _timeRanges = ['Day', 'Week', 'Month', 'Year'];
  String _selectedTimeRange = 'Week';

  // Controllers for tabs
  late TabController _tabController;

  // State for date selection
  DateTime _selectedDate = DateTime.now();

  // State for comparison toggle
  bool _compareWithPrevious = false;

  // Report data
  late List<EnergyReportData> _reportData;
  late Map<String, Color> _categoryColorMap;

  // Tips and alerts
  late List<EnergySavingTip> _energySavingTips;
  late List<EnergyAlert> _energyAlerts;
  late List<DeviceEnergyInfo> _deviceEnergyList;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    // Load appropriate data based on selected time range
    switch (_selectedTimeRange) {
      case 'Day':
        _reportData = EnergyReportData.generateDailyData();
        break;
      case 'Week':
        _reportData = EnergyReportData.generateWeeklyData();
        break;
      case 'Month':
        _reportData = EnergyReportData.generateMonthlyData();
        break;
      case 'Year':
        _reportData = EnergyReportData.generateYearlyData();
        break;
    }

    // Set up color map for categories
    _categoryColorMap = {
      // Placeholder: Map these colors to theme colors if desired
      'HVAC': Colors.blue, // Example: AppTheme.getSecondaryColor(context)
      'Appliance': Colors.green, // Example: AppTheme.getSuccessColor(context)
      'Light': Colors.amber, // Example: Colors.orangeAccent
      'Water': Colors.red, // Example: AppTheme.getErrorColor(context)
      'Other': Colors.purple, // Example: Colors.deepPurpleAccent
    };

    // Load tips and alerts
    _energySavingTips = EnergySavingTip.generateTips();
    _energyAlerts = EnergyAlert.generateAlerts();
    _deviceEnergyList = DeviceEnergyInfo.generateDeviceList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTimeRangeChanged(String range) {
    setState(() {
      _selectedTimeRange = range;
      _loadData();
    });
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _toggleComparison() {
    setState(() {
      _compareWithPrevious = !_compareWithPrevious;
    });
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report exported successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _scheduleReport() {
    // Show a dialog to schedule reports
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Schedule Regular Reports'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select frequency:'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Daily'),
                        selected: true,
                        onSelected: (_) {},
                        selectedColor: AppTheme.getPrimaryColor(context),
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary), // Use theme color
                      ),
                      ChoiceChip(
                        label: const Text('Weekly'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      ChoiceChip(
                        label: const Text('Monthly'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select delivery method:'),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Email'),
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppTheme.primaryColor,
                  ),
                  CheckboxListTile(
                    title: const Text('Push Notification'),
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppTheme.primaryColor,
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report scheduled successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Schedule'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final appState = Provider.of<AppState>(context); // Unused variable

    // Get current report data
    final currentReport = _reportData.isNotEmpty ? _reportData.last : null;
    final previousReport =
        _reportData.length > 1 ? _reportData[_reportData.length - 2] : null;

    // Sort devices by energy usage for top consumers
    final topDevices = List<DeviceEnergyInfo>.from(_deviceEnergyList)
      ..sort((a, b) => b.dailyUsage.compareTo(a.dailyUsage));

    // Format selected date
    final dateFormat =
        _selectedTimeRange == 'Day'
            ? DateFormat('EEE, MMM d, yyyy')
            : _selectedTimeRange == 'Week'
            ? DateFormat('MMM d')
            : _selectedTimeRange == 'Month'
            ? DateFormat('MMM yyyy')
            : DateFormat('yyyy');

    String dateRangeText;
    if (_selectedTimeRange == 'Day') {
      dateRangeText = dateFormat.format(_selectedDate);
    } else if (_selectedTimeRange == 'Week') {
      final weekStart = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));
      dateRangeText =
          '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
    } else if (_selectedTimeRange == 'Month') {
      dateRangeText = dateFormat.format(_selectedDate);
    } else {
      dateRangeText = dateFormat.format(_selectedDate);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with Date Selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Energy Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.date_range,
                      color: AppTheme.textPrimaryColor,
                    ),
                    onPressed: _selectDate,
                    tooltip: 'Select date',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: AppTheme.textPrimaryColor,
                    ),
                    onPressed: _exportReport,
                    tooltip: 'Export report',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.schedule,
                      color: AppTheme.textPrimaryColor,
                    ),
                    onPressed: _scheduleReport,
                    tooltip: 'Schedule reports',
                  ),
                ],
              ),
            ),

            // Time Period Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date display
                  Row(
                    children: [
                      Text(
                        dateRangeText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const Spacer(),
                      // Comparison toggle
                      Row(
                        children: [
                          const Text(
                            'Compare',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Switch(
                            value: _compareWithPrevious,
                            onChanged: (value) => _toggleComparison(),
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Time range selector (Day/Week/Month/Year)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _timeRanges.length,
                      itemBuilder: (context, index) {
                        final range = _timeRanges[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: ChoiceChip(
                            label: Text(range),
                            selected: _selectedTimeRange == range,
                            onSelected: (selected) {
                              if (selected) {
                                _onTimeRangeChanged(range);
                              }
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color:
                                  _selectedTimeRange == range
                                      ? Colors.white
                                      : AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Energy Usage Summary Card
            if (currentReport != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Energy Consumption',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${currentReport.energyUsage.toStringAsFixed(1)} kWh',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (previousReport != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      currentReport.energyUsage <
                                              previousReport.energyUsage
                                          ? AppTheme.getSuccessColor(context).withAlpha((0.1 * 255).round()) // Use theme color
                                          : AppTheme.getErrorColor(context).withAlpha((0.1 * 255).round()), // Use theme color
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      currentReport.energyUsage <
                                              previousReport.energyUsage
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color:
                                          currentReport.energyUsage <
                                                  previousReport.energyUsage
                                              ? AppTheme.getSuccessColor(context) // Use theme color
                                              : AppTheme.getErrorColor(context), // Use theme color
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${((currentReport.energyUsage - previousReport.energyUsage).abs() / previousReport.energyUsage * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            currentReport.energyUsage <
                                                    previousReport.energyUsage
                                                ? AppTheme.getSuccessColor(context) // Use theme color
                                                : AppTheme.getErrorColor(context), // Use theme color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (previousReport != null)
                          Text(
                            'VS. ${previousReport.energyUsage.toStringAsFixed(1)} kWh previous ${_selectedTimeRange.toLowerCase()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),

                        // Additional stats row
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatItem(
                              'Cost',
                              '\$${currentReport.cost.toStringAsFixed(2)}',
                              Icons.attach_money,
                              AppTheme.getSuccessColor(context), // Use theme color
                            ),
                            _buildStatItem(
                              'CO₂',
                              '${currentReport.co2Emissions.toStringAsFixed(1)} kg',
                              Icons.eco,
                              AppTheme.getSecondaryColor(context), // Use theme color (e.g., secondary)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Tab Bar for different chart views
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration( // Removed const
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1), // Use theme divider color
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                tabs: const [
                  Tab(text: 'Usage Trend'),
                  Tab(text: 'By Category'),
                  Tab(text: 'By Device'),
                ],
              ),
            ),

            // Tab Views with Charts
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Usage Trend Tab (Line Chart)
                  _buildUsageTrendTab(),

                  // Category Breakdown Tab (Bar Chart)
                  _buildCategoryBreakdownTab(),

                  // Device Breakdown Tab (Pie Chart)
                  _buildDeviceBreakdownTab(topDevices),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Usage Trend Tab
  Widget _buildUsageTrendTab() {
    final List<Map<String, dynamic>> lineChartData =
        _reportData.map((report) {
          String label = '';
          if (_selectedTimeRange == 'Day') {
            label = DateFormat('ha').format(report.date);
          } else if (_selectedTimeRange == 'Week') {
            label = DateFormat('E').format(report.date);
          } else if (_selectedTimeRange == 'Month') {
            label = DateFormat('MMM d').format(report.date);
          } else {
            label = DateFormat('yyyy').format(report.date);
          }

          return {
            'label': label,
            'value': report.energyUsage,
            'date': report.date,
          };
        }).toList();

   return SingleChildScrollView(
     padding: const EdgeInsets.all(16.0),
     child: Column( // Removed const
        crossAxisAlignment: CrossAxisAlignment.start,
        children: () { // Convert to function returning list
          // Build the list programmatically
          List<Widget> widgets = [
            // Line Chart
            Text(
              'Energy Consumption Over Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 16),
            LineChartWidget(
              data: lineChartData,
              xAxisLabel: _selectedTimeRange,
              yAxisLabel: 'kWh',
              showDots: _selectedTimeRange == 'Year',
              showAverage: true,
            ),
            SizedBox(height: 24),

            // Energy Saving Tips Section
            Text(
              'Energy Saving Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 16),
          ];

          // Add tips using addAll
          widgets.addAll(
            _energySavingTips
                .take(3)
                .map((tip) => _buildTipCard(tip))
                .toList(),
          );

          // Add SizedBox and Comparison widget
          widgets.addAll([
            SizedBox(height: 24),
            (_compareWithPrevious && _reportData.length >= 2)
                ? EnergyComparisionWidget( // Removed unnecessary Container wrapper
                    currentValue: _reportData.last.energyUsage,
                    previousValue: _reportData[_reportData.length - 2].energyUsage,
                    currentLabel: 'Current $_selectedTimeRange',
                    previousLabel: 'Previous $_selectedTimeRange',
                  )
                : const SizedBox.shrink(), // Ensure ternary structure is correct
            SizedBox(height: 24),

            // Unusual Activity Section
            Text(
              'Unusual Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 16),
          ]);

          // Add alerts using addAll
          widgets.addAll(
            _energyAlerts.map((alert) => _buildAlertCard(alert)).toList(),
          );

          return widgets; // Return the final list
        }(), // Immediately invoke the function
      ),
    );
  }

  // Category Breakdown Tab
  Widget _buildCategoryBreakdownTab() {
    final Map<String, double> categoryTotals = {};

    // Sum up category usage across all reports
    for (final report in _reportData) {
      report.deviceCategoryBreakdown.forEach((category, value) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + value;
      });
    }

    // Convert to format needed for BarChart
    final List<Map<String, dynamic>> barChartData =
        categoryTotals.entries
            .map(
              (entry) => {
                'label': entry.key,
                'name': entry.key,
                'value': entry.value / _reportData.length, // Average value
                'color': _categoryColorMap[entry.key],
              },
            )
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar Chart
          const Text(
            'Energy Consumption by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          BarChartWidget(
            data: barChartData,
            xAxisLabel: 'Categories',
            yAxisLabel: 'kWh',
            onBarSelected: (index) {
              // Handle bar selection
              // Bar selection callback exists, but no action is currently taken.
            },
          ),

          const SizedBox(height: 24),

          // Category Details
          const Text(
            'Category Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // List of categories with details
          ...categoryTotals.entries.map((entry) { // Added spread operator
            // Group devices by category
            final devicesInCategory =
                _deviceEnergyList
                    .where((device) => device.type == entry.key)
                    .toList();

            return _buildCategoryCard(
              entry.key,
              entry.value / _reportData.length,
              _categoryColorMap[entry.key] ?? Theme.of(context).disabledColor, // Use theme color
              devicesInCategory,
            );
          }), // Removed unnecessary .toList()
        ],
      ),
    );
  }

  // Device Breakdown Tab
  Widget _buildDeviceBreakdownTab(List<DeviceEnergyInfo> topDevices) {
    final Map<String, double> deviceData = {};
    final Map<String, Color> deviceColors = {};

    // Get data for pie chart
    for (final device in topDevices) {
      deviceData[device.name] = device.dailyUsage;
      deviceColors[device.name] = device.color;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie Chart
          const Text(
            'Energy Consumption by Device',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          PieChartWidget(
            data: deviceData,
            colorMap: deviceColors,
            centerText: 'Total',
            centerSubText:
                '${topDevices.fold(0.0, (sum, device) => sum + device.dailyUsage).toStringAsFixed(1)} kWh',
          ),

          const SizedBox(height: 24),

          // Top Energy Consumers
          const Text(
            'Top Energy Consumers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Top 3 devices
          // Correctly spread the mapped list
          ...topDevices
              .take(3)
              .map(
                (device) => DeviceEnergyCard(
                  deviceName: device.name,
                  deviceType: device.type,
                  energyUsage: device.dailyUsage,
                  cost: device.weeklyCost,
                  icon: IconData(
                    device.iconPath.codeUnits[0],
                    fontFamily: 'MaterialIcons',
                  ),
                  color: device.color,
                ),
              )
              , // Removed unnecessary .toList()

          const SizedBox(height: 24),

          // All Devices Table
          const Text(
            'All Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()), // Use theme color
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Device',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Usage',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Cost',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          // Correctly spread the mapped list
          ...topDevices
              .map(
                (device) => Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          device.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          device.type,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${device.dailyUsage.toStringAsFixed(1)} kWh',
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${device.weeklyCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              , // Removed unnecessary .toList()

          const SizedBox(height: 16),

          // Potential Savings Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppTheme.getSecondaryColor(context).withAlpha((0.1 * 255).round()), // Use theme color (e.g., secondary accent)
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row( // Removed const
                    children: [
                      Icon(Icons.savings, color: AppTheme.getSecondaryColor(context)), // Use theme color
                      SizedBox(width: 8),
                      Text(
                        'Potential Savings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getSecondaryColor(context), // Use theme color
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'By optimizing your device usage, you could save:',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Up to \$${_energySavingTips.fold(0.0, (sum, tip) => sum + tip.potentialSavings).toStringAsFixed(2)} per month',
                    style: TextStyle( // Removed const
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getSecondaryColor(context), // Use theme color
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'See the Energy Saving Tips section for details.',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(EnergySavingTip tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.getSuccessColor(context).withAlpha((0.1 * 255).round()), // Use theme color
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tip.icon, color: AppTheme.getSuccessColor(context), size: 24), // Use theme color
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Potential Savings: \$${tip.potentialSavings.toStringAsFixed(2)}/month',
                    style: TextStyle( // Removed const
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getSuccessColor(context), // Use theme color
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

  Widget _buildAlertCard(EnergyAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    alert.isImportant
                        ? AppTheme.getErrorColor(context).withAlpha((0.1 * 255).round()) // Use theme color
                        : AppTheme.getSecondaryColor(context).withAlpha((0.1 * 255).round()), // Use theme color (e.g., secondary accent)
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                alert.icon,
                color: alert.isImportant ? AppTheme.getErrorColor(context) : AppTheme.getSecondaryColor(context), // Use theme colors
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(alert.time), // Unnecessary string interpolation removed
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
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

  Widget _buildCategoryCard(
    String category,
    double usage,
    Color color,
    List<DeviceEnergyInfo> devices,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${usage.toStringAsFixed(1)} kWh',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            if (devices.isNotEmpty) const SizedBox(height: 8),
            if (devices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      devices
                          .map(
                            (device) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${device.dailyUsage.toStringAsFixed(1)} kWh',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
