import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickConverterWidget extends StatelessWidget {
  final String fromCurrency;
  final String toCurrency;
  final double exchangeRate;
  final Function(double) onAmountSelected;

  const QuickConverterWidget({
    Key? key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.exchangeRate,
    required this.onAmountSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<double> quickAmounts = [100, 500, 1000, 5000];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'flash_on',
                color: const Color(0xFF18214F),
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Hızlı Çevirici',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 3.h,
              childAspectRatio: 1.8,
            ),
            itemCount: quickAmounts.length,
            itemBuilder: (context, index) {
              final amount = quickAmounts[index];
              final convertedAmount = amount * exchangeRate;

              return GestureDetector(
                onTap: () => onAmountSelected(amount),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              '${CurrencyFormatter.formatNumber(amount, decimalPlaces: 0)} $fromCurrency',
                              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF18214F),
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              '${CurrencyFormatter.formatNumber(convertedAmount)} $toCurrency',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
