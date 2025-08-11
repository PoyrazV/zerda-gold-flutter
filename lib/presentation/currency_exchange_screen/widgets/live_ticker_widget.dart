import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LiveTickerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> tickerData;
  final bool isRefreshing;

  const LiveTickerWidget({
    Key? key,
    required this.tickerData,
    this.isRefreshing = false,
  }) : super(key: key);

  @override
  State<LiveTickerWidget> createState() => _LiveTickerWidgetState();
}

class _LiveTickerWidgetState extends State<LiveTickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 25),
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
      height: 8.h,
      color: const Color(0xFF9333EA),
      child: Stack(
        children: [
          // Scrolling ticker
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value * 100.w, 0),
                child: Row(
                  children: [
                    ...widget.tickerData.map((data) => _buildTickerItem(data)),
                    ...widget.tickerData.map((data) => _buildTickerItem(data)),
                  ],
                ),
              );
            },
          ),

          // Time indicator
          Positioned(
            top: 1.h,
            right: 4.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '10:12',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTickerItem(Map<String, dynamic> data) {
    final bool isPositive = data['isPositive'] as bool;
    final Color changeColor =
        isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Currency pair
          Text(
            data['pair'] as String,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),

          SizedBox(width: 2.w),

          // Price
          Text(
            CurrencyFormatter.formatExchangeRate(data['price'] as double),
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),

          SizedBox(width: 2.w),

          // Change percentage with mini chart indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini sparkline (simulated)
                Container(
                  width: 20,
                  height: 12,
                  child: CustomPaint(
                    painter: MiniSparklinePainter(
                      isPositive: isPositive,
                      color: changeColor,
                    ),
                  ),
                ),

                SizedBox(width: 1.w),

                Text(
                  CurrencyFormatter.formatPercentageChange(data['change'] as double),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Removed _formatPrice method - now using CurrencyFormatter.formatExchangeRate
}

class MiniSparklinePainter extends CustomPainter {
  final bool isPositive;
  final Color color;

  MiniSparklinePainter({
    required this.isPositive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Create a simple mini chart line
    if (isPositive) {
      // Upward trending line
      path.moveTo(0, size.height * 0.8);
      path.lineTo(size.width * 0.3, size.height * 0.6);
      path.lineTo(size.width * 0.6, size.height * 0.4);
      path.lineTo(size.width, size.height * 0.2);
    } else {
      // Downward trending line
      path.moveTo(0, size.height * 0.2);
      path.lineTo(size.width * 0.3, size.height * 0.4);
      path.lineTo(size.width * 0.6, size.height * 0.6);
      path.lineTo(size.width, size.height * 0.8);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
