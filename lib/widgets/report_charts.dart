import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import 'dart:math' as math;
import '../utils/animations.dart'; // Import AnimatedTapButton

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, Color> colorMap;
  final double centerRadius;
  final String centerText;
  final String centerSubText;

  const PieChartWidget({
    super.key,
    required this.data,
    required this.colorMap,
    this.centerRadius = 60.0,
    this.centerText = '',
    this.centerSubText = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for text color

    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.cardColor, // Use theme card color
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: data.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant), // Use theme color
                  ),
                )
              : PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Handle touch events if needed
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: centerRadius,
                    sections: _getSections(),
                  ),
                ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    final List<PieChartSectionData> sections = [];
    final entries = data.entries.toList();
    final total = data.values.fold(0.0, (a, b) => a + b);

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percentage = entry.value / total;

      final color =
          colorMap[entry.key] ?? Colors.primaries[i % Colors.primaries.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${(percentage * 100).toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle( // Use theme color for contrast
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                   ? Colors.white
                   : Colors.black,
          ),
          badgeWidget:
              centerText.isNotEmpty
                  ? _Badge(entry.key, size: 40, borderColor: color)
                  : null,
          badgePositionPercentageOffset: 1.4,
        ),
      );
    }
    return sections;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final double size;
  final Color borderColor;

  const _Badge(this.label, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Use theme surface color
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),        boxShadow: [ // Use theme shadow color
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha((0.1 * 255).round()),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label.split(' ')[0][0],
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String xAxisLabel;
  final String yAxisLabel;
  final bool animate;
  final Function(int)? onBarSelected;

  const BarChartWidget({
    super.key,
    required this.data,
    this.xAxisLabel = '',
    this.yAxisLabel = '',
    this.animate = true,
    this.onBarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for text color

    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.cardColor, // Use theme card color
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: data.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                     style: TextStyle(color: theme.colorScheme.onSurfaceVariant), // Use theme color
                  ),
                )
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY() * 1.2, // Calculate maxY based on potentially empty data
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: theme.colorScheme.inverseSurface, // Use theme tooltip color
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          // Safety check for index
                          if (groupIndex >= 0 && groupIndex < data.length) {
                            return BarTooltipItem(
                              '${data[groupIndex]['name']}\n',
                              TextStyle( // Use theme tooltip text color
                                color: theme.colorScheme.onInverseSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${rod.toY.toStringAsFixed(1)} kWh', // Use appropriate unit
                                  style: TextStyle( // Use theme tooltip text color
                                    color: theme.colorScheme.onInverseSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }
                          return null; // Return null if index is out of bounds
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (event is FlTapUpEvent &&
                            barTouchResponse != null &&
                            barTouchResponse.spot != null &&
                            onBarSelected != null) {
                          onBarSelected!(barTouchResponse.spot!.touchedBarGroupIndex);
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => _bottomTitles(value, meta, theme), // Pass theme
                          reservedSize: 42,
                        ),
                        axisNameWidget: Text(
                          xAxisLabel,
                          style: TextStyle( // Use theme color
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => _leftTitles(value, meta, theme), // Pass theme
                        ),
                        axisNameWidget: Text(
                          yAxisLabel,
                          style: TextStyle( // Use theme color
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: theme.dividerColor.withAlpha((0.5 * 255).round()), strokeWidth: 1); // Use theme divider color
                      },
                      horizontalInterval: _getMaxY() / 5, // Use calculated maxY
                    ),
                    barGroups: _getBarGroups(theme), // Pass theme
                  ),
                ),
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta, ThemeData theme) { // Add theme parameter
    final index = value.toInt();
    if (index >= 0 && index < data.length) {
      String title = data[index]['label'] ?? '';
      if (title.length > 10) {
        title = '${title.substring(0, 8)}...'; // Corrected interpolation
      }
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 10,
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            title,
            style: TextStyle( // Use theme color
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _leftTitles(double value, TitleMeta meta, ThemeData theme) { // Add theme parameter
    if (value == 0) {
      return const SizedBox();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toStringAsFixed(1),
        style: TextStyle( // Use theme color
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  double _getMaxY() {
    double maxY = 0;
    for (final item in data) {
      final value = item['value'] as double;
      if (value > maxY) {
        maxY = value;
      }
    }
    return maxY == 0 ? 10 : maxY;
  }

  List<BarChartGroupData> _getBarGroups(ThemeData theme) { // Add theme parameter
    return List.generate(data.length, (index) {
      final item = data[index];
      final value = item['value'] as double;
      // Use theme's primary color as default if item['color'] is null
      final color = item['color'] as Color? ?? theme.colorScheme.primary;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 18,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY() * 1.2,
              color: theme.colorScheme.surfaceContainerHighest, // Use theme background color
            ),
          ),
        ],
      );
    });
  }
}

class LineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<Color> gradientColors;
  final String xAxisLabel;
  final String yAxisLabel;
  final bool showDots;
  final bool showAverage;
  final bool animate;

  const LineChartWidget({
    super.key,
    required this.data,
    this.gradientColors = const [AppTheme.primaryColor, Color(0xFF81C784)],
    this.xAxisLabel = '',
    this.yAxisLabel = '',
    this.showDots = false,
    this.showAverage = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context); // Get theme for text color

    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.cardColor, // Use theme card color
        child: Padding(
          padding: const EdgeInsets.only(
            top: 24,
            right: 16,
            left: 8,
            bottom: 16,
          ),
          child: data.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                     style: TextStyle(color: theme.colorScheme.onSurfaceVariant), // Use theme color
                  ),
                )
              : LineChart(
                  mainData(theme), // Pass theme
                ),
        ),
      ),
    );
  }

  LineChartData mainData(ThemeData theme) { // Add theme parameter
    final maxY = _getMaxY() * 1.2;
    final minY = _getMinY() * 0.8;
    final averageY = showAverage ? _getAverageY() : null;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxY - minY) / 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {          return FlLine(color: theme.dividerColor.withAlpha((0.5 * 255).round()), strokeWidth: 1); // Use theme divider color
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: theme.dividerColor.withAlpha((0.5 * 255).round()), strokeWidth: 1); // Use theme divider color
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: data.length > 10 ? (data.length / 5).ceilToDouble() : 1,
            getTitlesWidget: (value, meta) => _bottomTitles(value, meta, theme), // Pass theme
          ),
          axisNameWidget: Text(
            xAxisLabel,
            style: TextStyle( // Use theme color
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (value, meta) => _leftTitles(value, meta, theme), // Pass theme
            reservedSize: 42,
          ),
          axisNameWidget: Text(
            yAxisLabel,
            style: TextStyle( // Use theme color
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border( // Use theme divider color
          bottom: BorderSide(color: theme.dividerColor),
          left: BorderSide(color: theme.dividerColor),
        ),
      ),
      minX: 0,
      maxX: data.length - 1.0,
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: theme.colorScheme.inverseSurface, // Use theme tooltip color
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots
                .map((barSpot) {
                  final index = barSpot.x.toInt();
                  if (index >= 0 && index < data.length) {
                    final item = data[index];
                    final label = item['label'] ?? '';
                    final value = item['value'] as double;

                    return LineTooltipItem(
                      '${label.isEmpty ? 'Point $index' : label}\n',
                      TextStyle( // Use theme tooltip text color
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${value.toStringAsFixed(1)} kWh',
                          style: TextStyle( // Use theme tooltip text color
                            color: theme.colorScheme.onInverseSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                })
                .whereType<LineTooltipItem>()
                .toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(data.length, (index) {
            return FlSpot(index.toDouble(), data[index]['value'] as double);
          }),
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: gradientColors[1],
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface, // Use theme surface color for contrast
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors:
                  gradientColors
                      .map((color) => color.withAlpha((0.3 * 255).round()))
                      .toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        // Add average line if needed
        if (averageY != null)
          LineChartBarData(
            spots: [FlSpot(0, averageY), FlSpot(data.length - 1.0, averageY)], // Ensure maxX is double
            isCurved: false,
            color: theme.colorScheme.error, // Use theme error color
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ),
      ],
      extraLinesData:
          averageY != null
              ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: averageY,
                    color: theme.colorScheme.error, // Use theme error color
                    strokeWidth: 2,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      style: TextStyle( // Use theme error color
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      labelResolver:
                          (line) => 'Avg: ${averageY.toStringAsFixed(1)}',
                    ),
                  ),
                ],
              )
              : null,
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta, ThemeData theme) { // Add theme parameter
    final index = value.toInt();
    if (index >= 0 && index < data.length) {
      final String text = data[index]['label'] ?? '';
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          text.length > 5 ? '${text.substring(0, 3)}..' : text,
          style: TextStyle( // Use theme color
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _leftTitles(double value, TitleMeta meta, ThemeData theme) { // Add theme parameter
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toStringAsFixed(1),
        style: TextStyle( // Use theme color
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  double _getMaxY() {
    double maxY = double.negativeInfinity;
    for (final item in data) {
      final value = item['value'] as double;
      if (value > maxY) {
        maxY = value;
      }
    }
    return maxY == double.negativeInfinity ? 10 : maxY;
  }

  double _getMinY() {
    double minY = double.infinity;
    for (final item in data) {
      final value = item['value'] as double;
      if (value < minY) {
        minY = value;
      }
    }
    return minY == double.infinity ? 0 : math.max(0, minY);
  }

  double _getAverageY() {
    if (data.isEmpty) return 0;
    double sum = 0;
    for (final item in data) {
      sum += item['value'] as double;
    }
    return sum / data.length;
  }
}

class EnergyComparisionWidget extends StatelessWidget {
  final double currentValue;
  final double previousValue;
  final String currentLabel;
  final String previousLabel;
  final String unit;

  const EnergyComparisionWidget({
    super.key, // Use super parameters
    required this.currentValue,
    required this.previousValue,
    this.currentLabel = 'Current',
    this.previousLabel = 'Previous',
    this.unit = 'kWh',
  }); // Removed super(key: key)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme
    final colorScheme = theme.colorScheme; // Get color scheme

    final difference = currentValue - previousValue;
    final percentChange =
        previousValue != 0 ? (difference / previousValue) * 100 : 0.0;
    final isIncrease = difference > 0;

    // Define colors based on theme
    final increaseColor = colorScheme.error; // Typically red for increase/bad
    final decreaseColor = AppTheme.getSuccessColor(context); // Typically green for decrease/good
    final currentColor = colorScheme.primary;
    final previousColor = colorScheme.secondary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor, // Use theme card color
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text( // Removed const
              'Comparison',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface, // Use theme text color
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildValueColumn(
                    currentValue,
                    currentLabel,
                    currentColor, // Use theme color
                    theme, // Pass theme
                  ),
                ),
                Container(height: 50, width: 1, color: theme.dividerColor), // Use theme divider color
                Expanded(
                  child: _buildValueColumn(
                    previousValue,
                    previousLabel,
                    previousColor, // Use theme color
                    theme, // Pass theme
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncrease ? increaseColor : decreaseColor, // Use theme colors
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncrease ? '+' : ''}${difference.toStringAsFixed(1)} $unit (${percentChange.abs().toStringAsFixed(1)}%)',
                  style: theme.textTheme.titleMedium?.copyWith( // Use theme text style
                    color: isIncrease ? increaseColor : decreaseColor, // Use theme colors
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueColumn(double value, String label, Color color, ThemeData theme) { // Pass theme
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith( // Use theme text style
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: theme.textTheme.headlineSmall?.copyWith( // Use theme text style
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DeviceEnergyCard extends StatelessWidget {
  final String deviceName;
  final String deviceType;
  final double energyUsage;
  final double cost;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DeviceEnergyCard({
    super.key,
    required this.deviceName,
    required this.deviceType,
    required this.energyUsage,
    required this.cost,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme
    final colorScheme = theme.colorScheme; // Get color scheme

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: theme.cardColor, // Use theme card color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Replace InkWell with AnimatedTapButton
      child: AnimatedTapButton(
        onTap: onTap ?? () {}, // Use provided onTap or empty function
        borderRadius: BorderRadius.circular(12), // Match Card/InkWell radius
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: theme.textTheme.titleMedium?.copyWith( // Use theme text style
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface, // Use theme color
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceType,
                      style: theme.textTheme.bodyMedium?.copyWith( // Use theme text style
                        color: colorScheme.onSurfaceVariant, // Use theme color
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${energyUsage.toStringAsFixed(1)} kWh',
                    style: theme.textTheme.titleMedium?.copyWith( // Use theme text style
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface, // Use theme color
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${cost.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith( // Use theme text style
                      color: colorScheme.onSurfaceVariant, // Use theme color
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
