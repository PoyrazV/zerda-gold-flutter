import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';
import 'gold_bars_icon.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/gold_coin_prices_screen/gold_coin_prices_screen.dart';
import '../presentation/currency_converter_screen/currency_converter_screen.dart';
import '../presentation/price_alerts_screen/price_alerts_screen.dart';
import '../presentation/portfolio_management_screen/portfolio_management_screen.dart';
import '../services/feature_config_service.dart';
import 'feature_wrapper.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final String currentRoute;
  
  const CustomBottomNavigationBar({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  static final List<Map<String, dynamic>> _allNavItems = [
    {
      'title': 'Döviz',
      'icon': Icons.euro,
      'route': '/dashboard-screen',
      'feature': 'dashboard',
    },
    {
      'title': 'Altın',
      'icon': Icons.diamond,
      'route': '/gold-coin-prices-screen',
      'feature': 'goldPrices',
    },
    {
      'title': 'Çevirici',
      'icon': Icons.swap_horiz,
      'route': '/currency-converter-screen',
      'feature': 'converter',
    },
    {
      'title': 'Alarm',
      'icon': Icons.notifications,
      'route': '/price-alerts-screen',
      'feature': 'alarms',
    },
    {
      'title': 'Portföy',
      'icon': Icons.account_balance_wallet,
      'route': '/portfolio-management-screen',
      'feature': 'portfolio',
    },
  ];

  List<Map<String, dynamic>> get _enabledNavItems {
    final featureConfig = FeatureConfigService();
    return _allNavItems.where((item) {
      return featureConfig.isFeatureEnabled(item['feature'] as String);
    }).toList();
  }

  Widget _getPageForRoute(String route) {
    switch (route) {
      case '/dashboard-screen':
        return FeatureWrapper(
          featureName: 'dashboard',
          child: const DashboardScreen(),
        );
      case '/gold-coin-prices-screen':
        return FeatureWrapper(
          featureName: 'goldPrices',
          child: const GoldCoinPricesScreen(),
        );
      case '/currency-converter-screen':
        return FeatureWrapper(
          featureName: 'converter',
          child: const CurrencyConverterScreen(),
        );
      case '/price-alerts-screen':
        return FeatureWrapper(
          featureName: 'alarms',
          child: const PriceAlertsScreen(),
        );
      case '/portfolio-management-screen':
        return FeatureWrapper(
          featureName: 'portfolio',
          child: const PortfolioManagementScreen(),
        );
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18214F), // Dark navy background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 8.h,
          child: Row(
            children: _enabledNavItems.asMap().entries.map((entry) {
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
                                      ? const Color(0xFFE8D095) // Gold color for active
                                      : Colors.white, // White for inactive
                                  size: 25,
                                )
                              : Icon(
                                  item['icon'] as IconData,
                                  color: isActive
                                      ? const Color(0xFFE8D095) // Gold color for active
                                      : Colors.white, // White for inactive
                                  size: 25,
                                ),
                          ),
                          SizedBox(height: 0.2.h),
                          Flexible(
                            flex: 2,
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFE8D095) // Gold color for active
                                    : Colors.white, // White for inactive
                                fontSize: 10.sp,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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