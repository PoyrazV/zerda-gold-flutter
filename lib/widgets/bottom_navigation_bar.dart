import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final String currentRoute;
  
  const CustomBottomNavigationBar({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  static final List<Map<String, dynamic>> _navItems = [
    {
      'title': 'Döviz',
      'icon': Icons.attach_money,
      'route': '/dashboard-screen',
    },
    {
      'title': 'Altın',
      'icon': Icons.star,
      'route': '/gold-coin-prices-screen',
    },
    {
      'title': 'Çevirici',
      'icon': Icons.swap_horiz,
      'route': '/currency-converter-screen',
    },
    {
      'title': 'Alarm',
      'icon': Icons.notifications,
      'route': '/price-alerts-screen',
    },
    {
      'title': 'Portföy',
      'icon': Icons.account_balance_wallet,
      'route': '/portfolio-management-screen',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 8.h,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 1.w),
            child: Row(
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = currentRoute == item['route'];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (currentRoute != item['route']) {
                        Navigator.pushReplacementNamed(context, item['route'] as String);
                      }
                    },
                    child: Container(
                      height: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 0.5.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            flex: 3,
                            child: Icon(
                              item['icon'] as IconData,
                              color: isActive
                                  ? const Color(0xFF1976D2) // Material Blue
                                  : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          SizedBox(height: 0.2.h),
                          Flexible(
                            flex: 2,
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF1976D2) // Material Blue
                                    : Colors.grey[600],
                                fontSize: 9.sp,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}