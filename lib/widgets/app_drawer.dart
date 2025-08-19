import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'gold_bars_icon.dart';
import '../services/auth_service.dart';
import '../services/feature_config_service.dart';
import '../theme/app_colors.dart';
import '../services/theme_config_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late AuthService _authService;
  late FeatureConfigService _featureConfig;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _featureConfig = FeatureConfigService();
    _authService.addListener(_onAuthStateChanged);
    _featureConfig.addListener(_onFeatureConfigChanged);
    ThemeConfigService().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    _featureConfig.removeListener(_onFeatureConfigChanged);
    ThemeConfigService().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFeatureConfigChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild with new theme colors
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-detect current route
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    
    // Get auth state
    final isLoggedIn = _authService.isLoggedIn;
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.drawerBackground,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
            // Header with ZERDA and profile icon
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SvgPicture.asset(
                          'assets/images/zerda-gold-logo.svg',
                          height: 48,
                          colorFilter: ColorFilter.mode(
                            AppColors.drawerActive,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      if (isLoggedIn && _featureConfig.isProfileEnabled) 
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(context, '/user-profile-screen');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Show login button only if not logged in
                  if (!isLoggedIn)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/login-screen');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Menu items - only show if feature is enabled
            ..._buildEnabledMenuItems(currentRoute),
                ],
              ),
            ),
            
            // Footer section with COSMOS IT+ at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    const TextSpan(text: 'COSMOS IT'),
                    TextSpan(
                      text: '+',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
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

  List<Widget> _buildEnabledMenuItems(String? currentRoute) {
    List<Widget> menuItems = [];

    // Dashboard (Döviz)
    if (_featureConfig.isDashboardEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.euro, 
        'Döviz', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/dashboard-screen');
        },
        currentRoute == '/dashboard-screen'
      ));
    }

    // Gold Prices (Altın)
    if (_featureConfig.isGoldPricesEnabled) {
      menuItems.add(_buildMenuItemCustomIcon(
        GoldBarsIcon(
          color: currentRoute == '/gold-coin-prices-screen' 
              ? AppColors.drawerActive
              : Colors.white.withOpacity(0.9),
          size: 22,
        ), 
        'Altın', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/gold-coin-prices-screen');
        },
        currentRoute == '/gold-coin-prices-screen'
      ));
    }

    // Currency Converter (Çevirici)
    if (_featureConfig.isConverterEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.swap_horiz, 
        'Döviz/Altın Çevirici', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/currency-converter-screen');
        },
        currentRoute == '/currency-converter-screen'
      ));
    }

    // Alarms (Alarmlar)
    if (_featureConfig.isAlarmsEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.notifications_active, 
        'Alarmlar', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/price-alerts-screen');
        },
        currentRoute == '/price-alerts-screen'
      ));
    }

    // Portfolio (Portföyüm)
    if (_featureConfig.isPortfolioEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.account_balance_wallet, 
        'Portföyüm', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/portfolio-management-screen');
        },
        currentRoute == '/portfolio-management-screen'
      ));
    }

    // Watchlist (Takip Listem)
    if (_featureConfig.isWatchlistEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.bookmark, 
        'Takip Listem', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/watchlist-screen');
        },
        currentRoute == '/watchlist-screen'
      ));
    }

    // Profit/Loss Calculator (Kar/Zarar Hesaplama)
    if (_featureConfig.isProfitLossCalculatorEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.trending_up, 
        'Kar / Zarar Hesaplama', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/profit-loss-calculator-screen');
        },
        currentRoute == '/profit-loss-calculator-screen'
      ));
    }

    // Performance History (Performans Geçmişi)
    if (_featureConfig.isPerformanceHistoryEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.receipt_long, 
        'Performans Geçmişi', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/winners-losers-screen');
        },
        currentRoute == '/winners-losers-screen'
      ));
    }

    // Sarrafiye İşçilikleri
    if (_featureConfig.isSarrafiyeIscilikEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.currency_exchange, 
        'Sarrafiye İşçilikleri', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/sarrafiye-iscilik-screen');
        },
        currentRoute == '/sarrafiye-iscilik-screen'
      ));
    }

    // Geçmiş Kurlar
    if (_featureConfig.isGecmisKurlarEnabled) {
      menuItems.add(_buildMenuItem(
        Icons.history, 
        'Geçmiş Kurlar', 
        () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/gecmis-kurlar-screen');
        },
        currentRoute == '/gecmis-kurlar-screen'
      ));
    }

    return menuItems;
  }
  
  Widget _buildMenuItemCustomIcon(Widget icon, String title, VoidCallback onTap, [bool isActive = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: isActive ? BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ) : null,
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.drawerActive : AppColors.drawerInactive,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        visualDensity: VisualDensity.compact,
        dense: true,
      ),
    );
  }
  
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, [bool isActive = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: isActive ? BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ) : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.drawerActive : AppColors.drawerInactive,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.drawerActive : AppColors.drawerInactive,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        visualDensity: VisualDensity.compact,
        dense: true,
      ),
    );
  }
}