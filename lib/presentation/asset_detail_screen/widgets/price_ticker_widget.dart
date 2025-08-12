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

  final List<Map<String, dynamic>> tickerData = [
    {
      "symbol": "USD/TRY",
      "price": "34.2850",
      "change": "+0.15",
      "changePercent": "+0.44%",
      "isPositive": true,
    },
    {
      "symbol": "EUR/TRY",
      "price": "37.1245",
      "change": "-0.08",
      "changePercent": "-0.22%",
      "isPositive": false,
    },
    {
      "symbol": "GBP/TRY",
      "price": "43.5678",
      "change": "+0.32",
      "changePercent": "+0.74%",
      "isPositive": true,
    },
    {
      "symbol": "GOLD",
      "price": "2,845.50",
      "change": "-12.30",
      "changePercent": "-0.43%",
      "isPositive": false,
    },
    {
      "symbol": "BRENT",
      "price": "82.45",
      "change": "+1.25",
      "changePercent": "+1.54%",
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
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.colorScheme.primaryContainer,
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
                ...tickerData.map((item) => _buildTickerItem(item)),
                SizedBox(width: 20.w),
                ...tickerData.map((item) => _buildTickerItem(item)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTickerItem(Map<String, dynamic> item) {
    final bool isPositive = item["isPositive"] as bool;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item["symbol"] as String,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            item["price"] as String,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 1.w),
          CustomIconWidget(
            iconName: isPositive ? 'keyboard_arrow_up' : 'keyboard_arrow_down',
            color: isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
            size: 16,
          ),
          Text(
            item["changePercent"] as String,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
