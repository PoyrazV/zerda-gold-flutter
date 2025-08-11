import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GoldNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GoldNavigationWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> navItems = [
      {
        'title': 'Döviz',
        'icon': Icons.currency_exchange,
      },
      {
        'title': 'Altın',
        'icon': Icons.star,
      },
      {
        'title': 'Çevirici',
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'Alarm',
        'icon': Icons.alarm,
      },
      {
        'title': 'Portföy',
        'icon': Icons.account_balance_wallet,
      },
    ];

    return Container(
      height: 9.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark secondary background
        border: Border(
          top: BorderSide(
            color: const Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = index == currentIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isActive
                            ? const Color(
                                0xFFFFD700) // Gold for active Altın tab
                            : const Color(
                                0xFF94A3B8), // Light gray for inactive
                        size: 22,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: isActive
                              ? const Color(
                                  0xFFFFD700) // Gold for active Altın tab
                              : const Color(
                                  0xFF94A3B8), // Light gray for inactive
                          fontSize: 10.sp,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
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
    );
  }
}
