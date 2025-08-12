import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';
import 'gold_bars_icon.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/gold_coin_prices_screen/gold_coin_prices_screen.dart';
import '../presentation/currency_converter_screen/currency_converter_screen.dart';
import '../presentation/price_alerts_screen/price_alerts_screen.dart';
import '../presentation/portfolio_management_screen/portfolio_management_screen.dart';

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
      'icon': Icons.diamond,
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

  Widget _getPageForRoute(String route) {
    switch (route) {
      case '/dashboard-screen':
        return const DashboardScreen();
      case '/gold-coin-prices-screen':
        return const GoldCoinPricesScreen();
      case '/currency-converter-screen':
        return const CurrencyConverterScreen();
      case '/price-alerts-screen':
        return const PriceAlertsScreen();
      case '/portfolio-management-screen':
        return const PortfolioManagementScreen();
      default:
        return const DashboardScreen();
    }
  }

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
          child: Row(
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = currentRoute == item['route'];

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                      if (currentRoute != item['route']) {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return _getPageForRoute(item['route'] as String);
                            },
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child;
                            },
                            transitionDuration: Duration.zero,
                            settings: RouteSettings(name: item['route'] as String),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            flex: 3,
                            child: item['title'] == 'Altın' 
                              ? GoldBarsIcon(
                                  color: isActive
                                      ? const Color(0xFF1976D2) // Material Blue
                                      : Colors.grey[600]!,
                                  size: 20,
                                )
                              : Icon(
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
    );
  }
}