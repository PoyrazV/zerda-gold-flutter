import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/theme_config_service.dart';

class InteractiveChartWidget extends StatefulWidget {
  final String assetSymbol;

  const InteractiveChartWidget({
    Key? key,
    required this.assetSymbol,
  }) : super(key: key);

  @override
  State<InteractiveChartWidget> createState() => _InteractiveChartWidgetState();
}

class _InteractiveChartWidgetState extends State<InteractiveChartWidget> {
  String selectedTimeframe = '1D';
  final List<String> timeframes = ['1D', '1W', '1M', '3M', '1Y', '5Y'];

  final Map<String, List<FlSpot>> chartData = {
    '1D': [
      FlSpot(0, 34.20),
      FlSpot(1, 34.25),
      FlSpot(2, 34.18),
      FlSpot(3, 34.30),
      FlSpot(4, 34.28),
      FlSpot(5, 34.35),
      FlSpot(6, 34.29),
    ],
    '1W': [
      FlSpot(0, 33.80),
      FlSpot(1, 34.10),
      FlSpot(2, 34.25),
      FlSpot(3, 34.15),
      FlSpot(4, 34.30),
      FlSpot(5, 34.28),
      FlSpot(6, 34.35),
    ],
    '1M': [
      FlSpot(0, 32.50),
      FlSpot(5, 33.20),
      FlSpot(10, 33.80),
      FlSpot(15, 34.10),
      FlSpot(20, 34.25),
      FlSpot(25, 34.30),
      FlSpot(30, 34.35),
    ],
    '3M': [
      FlSpot(0, 30.80),
      FlSpot(15, 31.50),
      FlSpot(30, 32.20),
      FlSpot(45, 33.10),
      FlSpot(60, 33.80),
      FlSpot(75, 34.20),
      FlSpot(90, 34.35),
    ],
    '1Y': [
      FlSpot(0, 28.50),
      FlSpot(60, 30.20),
      FlSpot(120, 31.80),
      FlSpot(180, 32.50),
      FlSpot(240, 33.20),
      FlSpot(300, 33.90),
      FlSpot(365, 34.35),
    ],
    '5Y': [
      FlSpot(0, 18.50),
      FlSpot(365, 22.20),
      FlSpot(730, 25.80),
      FlSpot(1095, 28.50),
      FlSpot(1460, 31.20),
      FlSpot(1825, 34.35),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTimeframeSelector(),
          SizedBox(height: 3.h),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      height: 4.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.dividerLight,
          width: 1,
        ),
      ),
      child: Row(
        children: timeframes.map((timeframe) {
          final bool isSelected = selectedTimeframe == timeframe;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTimeframe = timeframe;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? ThemeConfigService().primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    timeframe,
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? ThemeConfigService().secondaryColor
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    final spots = chartData[selectedTimeframe] ?? [];
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return Container(
      height: 30.h,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.dividerLight,
                strokeWidth: 1,
              );
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
                reservedSize: 30,
                interval: spots.length > 1 ? spots.last.x / 4 : 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _getBottomTitle(value.toInt()),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxY - minY) / 4,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatNumber(value),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: AppTheme.dividerLight,
              width: 1,
            ),
          ),
          minX: spots.isNotEmpty ? spots.first.x : 0,
          maxX: spots.isNotEmpty ? spots.last.x : 1,
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.primaryColor,
                  AppTheme.lightTheme.colorScheme.primaryContainer,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
                    AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    CurrencyFormatter.formatExchangeRate(barSpot.y),
                    AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getBottomTitle(int value) {
    switch (selectedTimeframe) {
      case '1D':
        return '${value * 4}:00';
      case '1W':
        final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        return value < days.length ? days[value] : '';
      case '1M':
        return '${value + 1}';
      case '3M':
        return '${(value / 30).round() + 1}M';
      case '1Y':
        final months = [
          'Oca',
          'Şub',
          'Mar',
          'Nis',
          'May',
          'Haz',
          'Tem',
          'Ağu',
          'Eyl',
          'Eki',
          'Kas',
          'Ara'
        ];
        final monthIndex = (value / 30).round();
        return monthIndex < months.length ? months[monthIndex] : '';
      case '5Y':
        final year = (value / 365).round() + 2020;
        return year.toString();
      default:
        return value.toString();
    }
  }
}
