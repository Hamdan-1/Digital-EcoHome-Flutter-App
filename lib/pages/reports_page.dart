import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _timeRanges = ['Day', 'Week', 'Month', 'Year'];
  String _selectedTimeRange = 'Week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
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
                      Icons.calendar_today,
                      color: AppTheme.textPrimaryColor,
                    ),
                    onPressed: () {
                      // Show date picker
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppTheme.textPrimaryColor,
                    ),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ],
              ),
            ),

            // Time range selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
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
                          setState(() {
                            _selectedTimeRange = range;
                          });
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
            ),

            const SizedBox(height: 16),

            // Usage Summary Card
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
                            '${appState.weeklyUsage} kWh',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: Color(0xFF4CAF50),
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '15% less',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'VS. 92.1 kWh last week',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab Bar for charts
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                tabs: const [
                  Tab(text: 'Usage Breakdown'),
                  Tab(text: 'Usage Trend'),
                ],
              ),
            ),

            // Tab View for charts
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Usage Breakdown Tab (Pie Chart)
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Placeholder for pie chart
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: CircularProgressIndicator(
                                        value: 0.45,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF4CAF50),
                                            ),
                                        strokeWidth: 20,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: CircularProgressIndicator(
                                        value: 0.25,
                                        backgroundColor: Colors.transparent,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF2196F3),
                                            ),
                                        strokeWidth: 20,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: CircularProgressIndicator(
                                        value: 0.15,
                                        backgroundColor: Colors.transparent,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.orange,
                                            ),
                                        strokeWidth: 20,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: CircularProgressIndicator(
                                        value: 0.10,
                                        backgroundColor: Colors.transparent,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.purple,
                                            ),
                                        strokeWidth: 20,
                                      ),
                                    ),
                                    const Column(
                                      children: [
                                        Text(
                                          'Total',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                        Text(
                                          '78.3 kWh',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Legend
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildLegendItem(
                          'HVAC',
                          '45%',
                          '35.2 kWh',
                          const Color(0xFF4CAF50),
                        ),
                        _buildLegendItem(
                          'Appliances',
                          '25%',
                          '19.6 kWh',
                          const Color(0xFF2196F3),
                        ),
                        _buildLegendItem(
                          'Lighting',
                          '15%',
                          '11.7 kWh',
                          Colors.orange,
                        ),
                        _buildLegendItem(
                          'Others',
                          '10%',
                          '11.8 kWh',
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  // Usage Trend Tab (Line Chart)
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Placeholder for line chart
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Weekly Energy Trend',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 6,
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Usage',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Simple line chart visualization
                                SizedBox(
                                  height: 160,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildBarItem('Mon', 0.6),
                                      _buildBarItem('Tue', 0.8),
                                      _buildBarItem('Wed', 0.7),
                                      _buildBarItem('Thu', 0.9),
                                      _buildBarItem('Fri', 0.75),
                                      _buildBarItem('Sat', 0.4),
                                      _buildBarItem('Sun', 0.3),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Daily stats
                        const Text(
                          'Daily Stats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildDailyStatsItem('Monday', '12.6 kWh', '+5%'),
                        _buildDailyStatsItem('Tuesday', '16.8 kWh', '+12%'),
                        _buildDailyStatsItem('Wednesday', '14.7 kWh', '-5%'),
                        _buildDailyStatsItem('Thursday', '18.1 kWh', '+10%'),
                        _buildDailyStatsItem('Friday', '15.2 kWh', '-8%'),
                      ],
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

  Widget _buildLegendItem(
    String title,
    String percentage,
    String amount,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const Spacer(),
          Text(
            percentage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(String day, double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 130 * value,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF81C784)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStatsItem(String day, String amount, String change) {
    final isPositive = change.startsWith('+');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:
                  isPositive
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
