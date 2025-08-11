import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PriceTickerWidget extends StatefulWidget {
  const PriceTickerWidget({Key? key}) : super(key: key);

  @override
  State<PriceTickerWidget> createState() => _PriceTickerWidgetState();
}

class _PriceTickerWidgetState extends State<PriceTickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> _tickerData = [
    {
      "pair": "USD/TRY",
      "price": 32.4567,
      "change": 0.45,
      "isPositive": true,
    },
    {
      "pair": "EUR/TRY",
      "price": 35.2134,
      "change": -0.23,
      "isPositive": false,
    },
    {
      "pair": "GBP/TRY",
      "price": 41.0987,
      "change": 0.78,
      "isPositive": true,
    },
    {
      "pair": "CHF/TRY",
      "price": 36.7654,
      "change": -0.12,
      "isPositive": false,
    },
    {
      "pair": "JPY/TRY",
      "price": 0.2187,
      "change": 0.34,
      "isPositive": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_animation.value * 100.w, 0),
            child: Row(
              children: [
                ..._tickerData.map((data) => _buildTickerItem(data)),
                ..._tickerData.map((data) => _buildTickerItem(data)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTickerItem(Map<String, dynamic> data) {
    final bool isPositive = data['isPositive'] as bool;
    final Color changeColor =
        isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data['pair'] as String,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            CurrencyFormatter.formatExchangeRate(data['price'] as double),
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 1.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.2.h),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: isPositive ? 'arrow_upward' : 'arrow_downward',
                  color: changeColor,
                  size: 12,
                ),
                SizedBox(width: 0.5.w),
                Text(
                  CurrencyFormatter.formatPercentageChange(data['change'] as double),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
        ],
      ),
    );
  }
}
