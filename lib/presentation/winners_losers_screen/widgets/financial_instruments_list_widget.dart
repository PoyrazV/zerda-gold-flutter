import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FinancialInstrumentsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isWinners;
  final VoidCallback onRefresh;

  const FinancialInstrumentsListWidget({
    Key? key,
    required this.data,
    required this.isWinners,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final percentage = item['percentageChange'] as double;
        final Color changeColor = isWinners
            ? AppTheme.positiveGreen // Green for winners
            : AppTheme.negativeRed; // Red for losers
        final isLastItem = index == data.length - 1;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            border: isLastItem ? null : Border(
              bottom: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 1.2.h),
            child: Row(
              children: [
                // Left Column: Instrument name and description
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['name'] as String,
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item['description'] != null) ...[
                        SizedBox(height: 0.2.h),
                        Text(
                          item['description'] as String,
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Right Column: Percentage change
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.formatPercentage(percentage),
                    textAlign: TextAlign.right,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: changeColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
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
}
