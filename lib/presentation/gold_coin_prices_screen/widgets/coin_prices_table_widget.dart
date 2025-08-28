import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CoinPricesTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> goldCoinData;
  final VoidCallback onRefresh;

  const CoinPricesTableWidget({
    Key? key,
    required this.goldCoinData,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: goldCoinData.length,
      itemBuilder: (context, index) {
        final coin = goldCoinData[index];
        final bool isPositive = coin['isPositive'] as bool;
        final Color changeColor = isPositive
            ? const Color(0xFF10B981) // Green for positive
            : const Color(0xFFEF4444); // Red for negative
            
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Light gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
            child: Row(
              children: [
                // Coin type (Unit)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin['type'] as String,
                        style: TextStyle(
                          color: const Color(0xFF1E2939),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        CurrencyFormatter.formatPercentageChange(coin['change'] as double),
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Buy price (Alış)
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.formatTRY(coin['buyPrice'] as double),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF1E2939),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

                // Sell price (Satış)
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.formatTRY(coin['sellPrice'] as double),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF1E2939),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Removed _formatPrice method - now using CurrencyFormatter.formatTRY
}
