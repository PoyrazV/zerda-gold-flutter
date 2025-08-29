import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../services/theme_config_service.dart';

class CoinPricesTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> goldCoinData;
  final VoidCallback onRefresh;

  const CoinPricesTableWidget({
    Key? key,
    required this.goldCoinData,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<CoinPricesTableWidget> createState() => _CoinPricesTableWidgetState();
}

class _CoinPricesTableWidgetState extends State<CoinPricesTableWidget> {
  final ThemeConfigService _themeConfigService = ThemeConfigService();
  
  @override
  void initState() {
    super.initState();
    _themeConfigService.addListener(_onThemeChanged);
  }
  
  @override
  void dispose() {
    _themeConfigService.removeListener(_onThemeChanged);
    super.dispose();
  }
  
  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.goldCoinData.length,
      itemBuilder: (context, index) {
        final coin = widget.goldCoinData[index];
        final bool isPositive = coin['isPositive'] as bool;
        final Color changeColor = isPositive
            ? const Color(0xFF10B981) // Green for positive
            : const Color(0xFFEF4444); // Red for negative
            
        // Alternating row colors from theme
        final Color backgroundColor = index.isEven 
            ? _themeConfigService.listRowEven
            : _themeConfigService.listRowOdd;

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
                          color: _themeConfigService.listNameText,
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
                      color: _themeConfigService.listPriceText,
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
                      color: _themeConfigService.listPriceText,
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
