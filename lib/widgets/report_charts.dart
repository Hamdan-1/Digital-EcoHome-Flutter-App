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
        color: Colors.white, // Consider using theme card color
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: data.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: theme.disabledColor),
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
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
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
        color: Colors.white, // Consider using theme card color
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: data.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                     style: TextStyle(color: theme.disabledColor),
                  ),
                )
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY() * 1.2, // Calculate maxY based on potentially empty data
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.shade800,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          // Safety check for index
                          if (groupIndex >= 0 && groupIndex < data.length) {
                            return BarTooltipItem(
                              '${data[groupIndex]['name']}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${rod.toY.toStringAsFixed(1)} kWh', // Use appropriate unit
                                  style: const TextStyle(
                                    color: Colors.white,
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
                          getTitlesWidget: _bottomTitles,
                          reservedSize: 42,
                        ),
                        axisNameWidget: Text(
                          xAxisLabel,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: _leftTitles,
                        ),
                        axisNameWidget: Text(
                          yAxisLabel,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                      },
                      horizontalInterval: _getMaxY() / 5, // Use calculated maxY
                    ),
                    barGroups: _getBarGroups(), // Handles empty data internally now
                  ),
                ),
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
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
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == 0) {
      return const SizedBox();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toStringAsFixed(1),
        style: const TextStyle(
          color: AppTheme.textSecondaryColor,
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

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(data.length, (index) {
      final item = data[index];
      final value = item['value'] as double;
      final color = item['color'] as Color? ?? AppTheme.primaryColor;

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
              color: Colors.grey.shade100,
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
        color: Colors.white, // Consider using theme card color
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
                     style: TextStyle(color: theme.disabledColor),
                  ),
                )
              : LineChart(
                  mainData(), // mainData() needs to handle empty data if necessary
                ),
        ),
      ),
    );
  }

  LineChartData mainData() {
    final maxY = _getMaxY() * 1.2;
    final minY = _getMinY() * 0.8;
    final averageY = showAverage ? _getAverageY() : null;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxY - minY) / 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
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
            getTitlesWidget: _bottomTitles,
          ),
          axisNameWidget: Text(
            xAxisLabel,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY - minY) / 4,
            getTitlesWidget: _leftTitles,
            reservedSize: 42,
          ),
          axisNameWidget: Text(
            yAxisLabel,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      minX: 0,
      maxX: data.length - 1.0,
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.shade800,
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
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${value.toStringAsFixed(1)} kWh',
                          style: const TextStyle(
                            color: Colors.white,
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
                strokeColor: Colors.white,
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
            spots: [FlSpot(0, averageY), FlSpot(data.length - 1, averageY)],
            isCurved: false,
            color: Colors.red.shade300,
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
                    color: Colors.red.shade300,
                    strokeWidth: 2,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      style: TextStyle(
                        color: Colors.red.shade300,
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

  Widget _bottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index >= 0 && index < data.length) {
      final String text = data[index]['label'] ?? '';
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          text.length > 5 ? '${text.substring(0, 3)}..' : text, // Corrected interpolation
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toStringAsFixed(1),
        style: const TextStyle(
          color: AppTheme.textSecondaryColor,
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
    final difference = currentValue - previousValue;
    final percentChange =
        previousValue != 0 ? (difference / previousValue) * 100 : 0.0;
    final isIncrease = difference > 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildValueColumn(
                    currentValue,
                    currentLabel,
                    Colors.blue,
                  ),
                ),
                Container(height: 50, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildValueColumn(
                    previousValue,
                    previousLabel,
                    Colors.grey.shade700,
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
                  color: isIncrease ? Colors.red : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncrease ? '+' : ''}${difference.toStringAsFixed(1)} $unit (${percentChange.abs().toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncrease ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueColumn(double value, String label, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${cost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
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
