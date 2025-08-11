import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FavoriteCurrenciesWidget extends StatelessWidget {
  const FavoriteCurrenciesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> favoriteCurrencies = [
      {
        "symbol": "GBP/TRY",
        "price": "43.5670",
        "change": "+0.32",
        "changePercent": "+0.74%",
        "isPositive": true,
        "flag": "https://flagcdn.com/w320/gb.png",
        "sparklineData": [43.20, 43.35, 43.28, 43.45, 43.57],
      },
      {
        "symbol": "CHF/TRY",
        "price": "38.9245",
        "change": "-0.15",
        "changePercent": "-0.38%",
        "isPositive": false,
        "flag": "https://flagcdn.com/w320/ch.png",
        "sparklineData": [39.10, 38.95, 39.05, 38.88, 38.92],
      },
      {
        "symbol": "JPY/TRY",
        "price": "0.2285",
        "change": "+0.0012",
        "changePercent": "+0.53%",
        "isPositive": true,
        "flag": "https://flagcdn.com/w320/jp.png",
        "sparklineData": [0.2270, 0.2275, 0.2280, 0.2282, 0.2285],
      },
      {
        "symbol": "CAD/TRY",
        "price": "24.1850",
        "change": "-0.08",
        "changePercent": "-0.33%",
        "isPositive": false,
        "flag": "https://flagcdn.com/w320/ca.png",
        "sparklineData": [24.25, 24.20, 24.22, 24.18, 24.19],
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favori Dövizler',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to full favorites list
                },
                child: Text(
                  'Tümünü Gör',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteCurrencies.length,
              itemBuilder: (context, index) {
                return _buildFavoriteCurrencyCard(
                  context,
                  favoriteCurrencies[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCurrencyCard(
      BuildContext context, Map<String, dynamic> currency) {
    final bool isPositive = currency["isPositive"] as bool;
    final String symbol = currency["symbol"] as String;
    final String price = currency["price"] as String;
    final String change = currency["change"] as String;
    final String changePercent = currency["changePercent"] as String;
    final String flag = currency["flag"] as String;
    final List<double> sparklineData =
        (currency["sparklineData"] as List).cast<double>();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/asset-detail-screen');
      },
      onLongPress: () {
        _showQuickActions(context, symbol);
      },
      child: Container(
        width: 45.w,
        margin: EdgeInsets.only(right: 3.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    image: DecorationImage(
                      image: NetworkImage(flag),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    symbol,
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CustomIconWidget(
                  iconName: 'favorite',
                  color: AppTheme.negativeRed,
                  size: 16,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              "₺$price",
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName:
                      isPositive ? 'keyboard_arrow_up' : 'keyboard_arrow_down',
                  color: isPositive
                      ? AppTheme.positiveGreen
                      : AppTheme.negativeRed,
                  size: 14,
                ),
                Text(
                  changePercent,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: isPositive
                        ? AppTheme.positiveGreen
                        : AppTheme.negativeRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Expanded(
              child: Container(
                width: double.infinity,
                child: CustomPaint(
                  painter: SparklinePainter(
                    data: sparklineData,
                    color: isPositive
                        ? AppTheme.positiveGreen
                        : AppTheme.negativeRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, String symbol) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                symbol,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              _buildQuickActionItem(
                context,
                'Portföye Ekle',
                'add_circle_outline',
                () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/portfolio-management-screen');
                },
              ),
              _buildQuickActionItem(
                context,
                'Alarm Kur',
                'notifications_none',
                () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/price-alerts-screen');
                },
              ),
              _buildQuickActionItem(
                context,
                'Favorilerden Çıkar',
                'favorite_border',
                () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.primaryColor,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 2.w),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double minValue = data.reduce((a, b) => a < b ? a : b);
    final double maxValue = data.reduce((a, b) => a > b ? a : b);
    final double range = maxValue - minValue;

    if (range == 0) return;

    for (int i = 0; i < data.length; i++) {
      final double x = (i / (data.length - 1)) * size.width;
      final double y =
          size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
