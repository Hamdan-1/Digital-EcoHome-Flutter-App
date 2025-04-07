import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import '../theme.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';

class UsageChart extends StatefulWidget {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final bool showAxis;
  final double lineWidth;
  final bool animate;
  final double? maxHeight;
  final Color? gradientStartColor;
  final Color? gradientEndColor;

  const UsageChart({
    Key? key,
    required this.data,
    this.lineColor = AppTheme.primaryColor,
    this.fillColor = const Color(0x204CAF50), // Semi-transparent primary color
    this.showAxis = true,
    this.lineWidth = 2.0,
    this.animate = true,
    this.maxHeight,
    this.gradientStartColor,
    this.gradientEndColor,
  }) : super(key: key);

  @override
  State<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends State<UsageChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.animate) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onTapUp: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            _updateTouchedIndex(localPosition);
          },
          onHorizontalDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            _updateTouchedIndex(localPosition);
          },
          onHorizontalDragEnd: (_) => setState(() => _touchedIndex = null),
          onTapDown: (_) => HapticFeedback.lightImpact(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            child: Stack(
              children: [
                LineChart(
                  mainData(),
                  duration: Duration(milliseconds: widget.animate ? 800 : 0),
                ),
                if (_touchedIndex != null &&
                    _touchedIndex! < widget.data.length &&
                    _touchedIndex! >= 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.data[_touchedIndex!].toStringAsFixed(1)} kW',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.lineColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  LineChartData mainData() {
    final maxValue = widget.data.reduce((a, b) => math.max(a, b)) * 1.2;

    return LineChartData(
      gridData: FlGridData(
        show: widget.showAxis,
        drawVerticalLine: widget.showAxis,
        horizontalInterval: maxValue / 4,
        verticalInterval: 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: widget.showAxis,
            reservedSize: 22,
            interval: widget.data.length ~/ 6 > 0 ? widget.data.length / 6 : 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0 || value < 0 || value >= widget.data.length)
                return const SizedBox();
              final index = value.toInt();
              final hoursAgo = widget.data.length - 1 - index;

              if (hoursAgo % 4 == 0 ||
                  hoursAgo == 0 ||
                  hoursAgo == widget.data.length - 1) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    hoursAgo == 0 ? 'Now' : '${hoursAgo}h',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: widget.showAxis,
            interval: maxValue / 2,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 10,
                  ),
                ),
              );
            },
            reservedSize: 28,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: widget.data.length - 1.0,
      minY: 0,
      maxY: maxValue,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white.withOpacity(0.8),
          tooltipRoundedRadius: 8,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              final hoursAgo = widget.data.length - 1 - index;

              return LineTooltipItem(
                '${widget.data[index].toStringAsFixed(1)} kW\n',
                TextStyle(color: widget.lineColor, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: hoursAgo == 0 ? 'Now' : '$hoursAgo hours ago',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (event is! FlTapUpEvent &&
                event is! FlPanEndEvent &&
                touchResponse != null &&
                touchResponse.lineBarSpots != null &&
                touchResponse.lineBarSpots!.isNotEmpty) {
              _touchedIndex = touchResponse.lineBarSpots![0].x.toInt();
            } else {
              _touchedIndex = null;
            }
          });
        },
        handleBuiltInTouches: true,
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(widget.data.length, (index) {
            return FlSpot(
              index.toDouble(),
              widget.data[index] * _animation.value,
            );
          }),
          isCurved: true,
          gradient: LinearGradient(
            colors: [widget.lineColor.withOpacity(0.8), widget.lineColor],
          ),
          barWidth: widget.lineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: widget.lineColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.gradientStartColor ?? widget.lineColor.withOpacity(0.3),
                widget.gradientEndColor ?? widget.lineColor.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _updateTouchedIndex(Offset localPosition) {
    final chartWidth = context.size?.width ?? 300;
    final indexPosition = localPosition.dx / chartWidth * widget.data.length;
    final index = indexPosition.round();

    setState(() {
      if (index >= 0 && index < widget.data.length) {
        _touchedIndex = index;
      } else {
        _touchedIndex = null;
      }
    });
  }
}
