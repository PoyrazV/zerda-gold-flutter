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
    }

    return Column(
      children: [
        Container(
          height: 27.w, // Same height as ticker_section
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
          padding: EdgeInsets.only(bottom: 2.w),
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
      width: 26.5.w, // Same width as ticker_section
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      child: GestureDetector(
        onTap: widget.onAddPressed ?? () {
          Navigator.pushNamed(context, '/asset-selection-screen');
        },
        child: Container(
          padding: EdgeInsets.all(2.5.w),
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
            children: [
              Icon(
                Icons.add,
                color: Colors.white,
                size: 6.w,
              ),
              SizedBox(height: 1.w),
              Text(
                'EKLE',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 3.w,
                  fontWeight: FontWeight.w600,
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
        width: 26.5.w, // Same width as ticker_section
        margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 0.5.w),
            Column(
              children: [
                Text(
                  data['symbol'] as String? ?? '',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 3.3.w,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.w),
                Text(
                  CurrencyFormatter.formatTRY(data['price'] as double? ?? 0.0, decimalPlaces: 4),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 3.5.w,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 0.5.w, vertical: 0.3.w),
              decoration: BoxDecoration(
                color: isPositive 
                    ? AppTheme.positiveGreen.withOpacity(0.2)
                    : AppTheme.negativeRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isPositive 
                      ? AppTheme.positiveGreen.withOpacity(0.3)
                      : AppTheme.negativeRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive
                          ? AppTheme.positiveGreen
                          : AppTheme.negativeRed,
                      size: 2.5.w,
                    ),
                    SizedBox(width: 0.5.w),
                    Text(
                      '%${(data['changePercent'] as double? ?? 0.0).abs().toStringAsFixed(2).replaceAll('.', ',')}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontSize: 2.7.w,
                        fontWeight: FontWeight.w500,
                        color: isPositive 
                            ? AppTheme.positiveGreen
                            : AppTheme.negativeRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}