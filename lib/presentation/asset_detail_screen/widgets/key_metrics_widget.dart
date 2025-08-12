import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class KeyMetricsWidget extends StatelessWidget {
  final String openingPrice;
  final String previousClose;
  final String dailyHigh;
  final String dailyLow;
  final String weeklyPerformance;
  final bool weeklyIsPositive;

  const KeyMetricsWidget({
    Key? key,
    required this.openingPrice,
    required this.previousClose,
    required this.dailyHigh,
    required this.dailyLow,
    required this.weeklyPerformance,
    required this.weeklyIsPositive,
  }) : super(key: key);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temel Veriler',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricsGrid(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Açılış',
                openingPrice,
                CustomIconWidget(
                  iconName: 'schedule',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Önceki Kapanış',
                previousClose,
                CustomIconWidget(
                  iconName: 'history',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Günlük Yüksek',
                dailyHigh,
                CustomIconWidget(
                  iconName: 'keyboard_arrow_up',
                  color: AppTheme.positiveGreen,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Günlük Düşük',
                dailyLow,
                CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: AppTheme.negativeRed,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          'Haftalık Performans',
          weeklyPerformance,
          CustomIconWidget(
            iconName: weeklyIsPositive ? 'trending_up' : 'trending_down',
            color: weeklyIsPositive
                ? AppTheme.positiveGreen
                : AppTheme.negativeRed,
            size: 20,
          ),
          isFullWidth: true,
          valueColor:
              weeklyIsPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Widget icon, {
    bool isFullWidth = false,
    Color? valueColor,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.dividerLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.dataTextStyle(
              isLight: true,
              fontSize: 16,
            ).copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
