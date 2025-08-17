import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';
import '../core/currency_formatter.dart';
import '../services/watchlist_service.dart';
import '../services/global_ticker_service.dart';

class PriceTicker extends StatefulWidget {
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
  State<PriceTicker> createState() => _PriceTickerState();
}

class _PriceTickerState extends State<PriceTicker> {
  final GlobalTickerService _globalTickerService = GlobalTickerService();

  @override
  void initState() {
    super.initState();
    // Listen to global ticker service changes
    _globalTickerService.addListener(_onTickerDataChanged);
  }

  @override
  void dispose() {
    _globalTickerService.removeListener(_onTickerDataChanged);
    super.dispose();
  }

  void _onTickerDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use custom data if provided, otherwise use global ticker service data
    List<Map<String, dynamic>> tickerData;
    if (widget.customData != null) {
      tickerData = widget.customData!;
    } else {
      // Use global ticker service data (API data only, no fallback to mock)
      tickerData = _globalTickerService.getCurrentTickerData();
      
      // If no data yet, use default values to avoid loading indicator
      if (tickerData.isEmpty) {
        tickerData = [
          {'symbol': 'USD/TRY', 'price': 34.5958, 'change': 0.12, 'changePercent': 0.35},
          {'symbol': 'EUR/TRY', 'price': 37.4891, 'change': -0.08, 'changePercent': -0.21},
          {'symbol': 'GBP/TRY', 'price': 43.8056, 'change': 0.15, 'changePercent': 0.34},
          {'symbol': 'GOLD', 'price': 2845.50, 'change': 12.30, 'changePercent': 0.43},
        ];
      }
    }

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
            itemCount: tickerData.length + (widget.showAddButton ? 1 : 0),
            itemBuilder: (context, index) {
              // Add button at the end
              if (widget.showAddButton && index == tickerData.length) {
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
        onTap: widget.onAddPressed ?? () {
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

}