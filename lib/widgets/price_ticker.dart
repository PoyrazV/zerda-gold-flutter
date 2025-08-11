import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../theme/app_theme.dart';
import '../services/watchlist_service.dart';

class PriceTicker extends StatelessWidget {
  final List<Map<String, dynamic>>? customData;
  final bool showAddButton;
  final VoidCallback? onAddPressed;
  
  const PriceTicker({
    Key? key,
    this.customData,
    this.showAddButton = true,
    this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use custom data if provided, otherwise use watchlist data or default data
    final watchlistItems = WatchlistService.getWatchlistItems();
    final tickerData = customData ?? (watchlistItems.isEmpty 
        ? _getDefaultTickerData()
        : watchlistItems.map((item) => {
            'symbol': item['code'],
            'price': item['buyPrice'],
            'change': item['change'],
            'changePercent': item['changePercent']
          }).toList());

    return Column(
      children: [
        Container(
          height: 10.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.colorScheme.primary,
                AppTheme.lightTheme.colorScheme.primaryContainer,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: EdgeInsets.only(bottom: 2.h),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemCount: tickerData.length + (showAddButton ? 1 : 0),
            itemBuilder: (context, index) {
              // Add button at the end
              if (showAddButton && index == tickerData.length) {
                return _buildAddButton(context);
              }

              final data = tickerData[index];
              final bool isPositive = (data['change'] as double? ?? 0) >= 0;

              return _buildTickerItem(context, data, isPositive);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      child: GestureDetector(
        onTap: onAddPressed ?? () {
          Navigator.pushNamed(context, '/asset-selection-screen');
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(height: 0.2.h),
              Text(
                'Ekle',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTickerItem(BuildContext context, Map<String, dynamic> data, bool isPositive) {
    return GestureDetector(
      onTap: () {
        // Navigate to asset detail screen
        Navigator.pushNamed(
          context,
          '/asset-detail-screen',
          arguments: {
            'code': data['symbol'] as String? ?? '',
          },
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                data['symbol'] as String? ?? '',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(height: 0.2.h),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      CurrencyFormatter.formatTRY(data['price'] as double? ?? 0.0, decimalPlaces: 4),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 0.5.w),
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive
                        ? AppTheme.positiveGreen
                        : AppTheme.negativeRed,
                    size: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDefaultTickerData() {
    return [
      {
        'symbol': 'USD/TRY',
        'price': 34.2156,
        'change': 0.0234,
        'changePercent': 0.068
      },
      {
        'symbol': 'EUR/TRY',
        'price': 37.1234,
        'change': -0.0456,
        'changePercent': -0.123
      },
      {
        'symbol': 'GBP/TRY',
        'price': 43.5678,
        'change': 0.1234,
        'changePercent': 0.284
      },
      {
        'symbol': 'GOLD',
        'price': 2847.50,
        'change': -12.50,
        'changePercent': -0.437
      },
    ];
  }
}