import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';


class CurrencyTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> currencyData;
  final VoidCallback onRefresh;

  const CurrencyTableWidget({
    Key? key,
    required this.currencyData,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<CurrencyTableWidget> createState() => _CurrencyTableWidgetState();
}

class _CurrencyTableWidgetState extends State<CurrencyTableWidget>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<Color?>> _colorAnimations = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    for (var currency in widget.currencyData) {
      final code = currency['code'] as String;
      final controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );

      final colorAnimation = ColorTween(
        begin: Colors.transparent,
        end: const Color(0xFF1E293B).withValues(alpha: 0.3),
      ).animate(controller);

      _animationControllers[code] = controller;
      _colorAnimations[code] = colorAnimation;
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _animateUpdate(String currencyCode) {
    final controller = _animationControllers[currencyCode];
    if (controller != null) {
      controller.forward().then((_) {
        controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.currencyData.length,
      itemBuilder: (context, index) {
        final currency = widget.currencyData[index];
        final code = currency['code'] as String;
        final animation = _colorAnimations[code];
        
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Light gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return AnimatedBuilder(
          animation:
              animation ?? const AlwaysStoppedAnimation(Colors.transparent),
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: animation?.value ?? backgroundColor,
              ),
              child: _buildCurrencyRow(currency, index),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrencyRow(Map<String, dynamic> currency, int index) {
    final bool isPositive = currency['isPositive'] as bool;
    final Color changeColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return InkWell(
      onTap: () {
        _animateUpdate(currency['code'] as String);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            // Currency info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency['code'] as String,
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    currency['name'] as String,
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    currency['timestamp'] as String,
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Buy price
            Expanded(
              flex: 2,
              child: Text(
                CurrencyFormatter.formatExchangeRate(currency['buyPrice'] as double),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFFFFFF),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Sell price and percentage change
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    CurrencyFormatter.formatExchangeRate(currency['sellPrice'] as double),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    CurrencyFormatter.formatPercentageChange(currency['change'] as double),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed _formatPrice method - now using CurrencyFormatter.formatExchangeRate
}
