import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final double totalValue;
  final double gainLossPercentage;
  final double dailyChange;

  const PortfolioSummaryCard({
    Key? key,
    required this.totalValue,
    required this.gainLossPercentage,
    required this.dailyChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPositiveGain = gainLossPercentage >= 0;
    final bool isPositiveDailyChange = dailyChange >= 0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toplam Portföy Değeri',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary
                  .withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            CurrencyFormatter.formatTRY(totalValue),
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Kazanç/Kayıp',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimary
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName:
                              isPositiveGain ? 'trending_up' : 'trending_down',
                          color: isPositiveGain
                              ? AppTheme.positiveGreen
                              : AppTheme.negativeRed,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          CurrencyFormatter.formatPercentageChange(gainLossPercentage),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: isPositiveGain
                                ? AppTheme.positiveGreen
                                : AppTheme.negativeRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Günlük Değişim',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimary
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomIconWidget(
                          iconName: isPositiveDailyChange
                              ? 'arrow_upward'
                              : 'arrow_downward',
                          color: isPositiveDailyChange
                              ? AppTheme.positiveGreen
                              : AppTheme.negativeRed,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          CurrencyFormatter.formatTRY(dailyChange.abs()),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: isPositiveDailyChange
                                ? AppTheme.positiveGreen
                                : AppTheme.negativeRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
