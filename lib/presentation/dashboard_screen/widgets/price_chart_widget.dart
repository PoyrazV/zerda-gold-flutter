import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PriceChartWidget extends StatefulWidget {
  const PriceChartWidget({Key? key}) : super(key: key);

  @override
  State<PriceChartWidget> createState() => _PriceChartWidgetState();
}

class _PriceChartWidgetState extends State<PriceChartWidget> {
  String selectedTimeframe = '1D';
  final List<String> timeframes = ['1D', '1W', '1M'];

  final List<FlSpot> chartData = [
    const FlSpot(0, 34.10),
    const FlSpot(1, 34.15),
    const FlSpot(2, 34.08),
    const FlSpot(3, 34.22),
    const FlSpot(4, 34.18),
    const FlSpot(5, 34.28),
    const FlSpot(6, 34.25),
    const FlSpot(7, 34.30),
    const FlSpot(8, 34.28),
    const FlSpot(9, 34.35),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('USD/TRY Grafik',
                style: AppTheme.lightTheme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Row(
                children: timeframes.map((timeframe) {
              final bool isSelected = selectedTimeframe == timeframe;
              return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTimeframe = timeframe;
                    });
                  },
                  child: Container(
                      margin: EdgeInsets.only(left: 2.w),
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: isSelected
                                  ? AppTheme.lightTheme.primaryColor
                                  : AppTheme.dividerLight)),
                      child: Text(timeframe,
                          style: AppTheme.lightTheme.textTheme.labelMedium
                              ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondaryLight,
                                  fontWeight: FontWeight.w500))));
            }).toList()),
          ]),
          SizedBox(height: 3.h),
          SizedBox(
              height: 25.h,
              child: LineChart(LineChartData(
                  gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 0.05,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                            color: AppTheme.dividerLight, strokeWidth: 1);
                      }),
                  titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 2,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text('${value.toInt()}:00',
                                        style: AppTheme
                                            .lightTheme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: AppTheme
                                                    .textSecondaryLight)));
                              })),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              interval: 0.1,
                              reservedSize: 42,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Text(CurrencyFormatter.formatNumber(value),
                                    style: AppTheme
                                        .lightTheme.textTheme.labelSmall
                                        ?.copyWith(
                                            color:
                                                AppTheme.textSecondaryLight));
                              }))),
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppTheme.dividerLight)),
                  minX: 0,
                  maxX: 9,
                  minY: 34.0,
                  maxY: 34.4,
                  lineBarsData: [
                    LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        gradient: LinearGradient(colors: [
                          AppTheme.positiveGreen,
                          AppTheme.positiveGreen.withValues(alpha: 0.3),
                        ]),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                                colors: [
                                  AppTheme.positiveGreen.withValues(alpha: 0.3),
                                  AppTheme.positiveGreen.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter))),
                  ],
                  lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              return LineTooltipItem(
                                  CurrencyFormatter.formatTRY(barSpot.y, decimalPlaces: 4),
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold));
                            }).toList();
                          }))))),
        ]));
  }
}
