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
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: data.length,
      separatorBuilder: (context, index) => Divider(
        color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        height: 1,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final item = data[index];
        final percentage = item['percentageChange'] as double;
        final Color changeColor = isWinners
            ? AppTheme.positiveGreen // Green for winners
            : AppTheme.negativeRed; // Red for losers

        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            children: [
              // Left Column: Instrument name
              Expanded(
                flex: 3,
                child: Text(
                  item['name'] as String,
                  style: GoogleFonts.inter(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Center Column: Absolute change
              Expanded(
                flex: 2,
                child: Text(
                  item['absoluteChange'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Right Column: Percentage change
              Expanded(
                flex: 2,
                child: Text(
                  CurrencyFormatter.formatPercentage(percentage),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.robotoMono(
                    color: changeColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
