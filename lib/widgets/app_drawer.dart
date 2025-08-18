import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'gold_bars_icon.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF18214F), // Dark navy - matches header
              Color(0xFF1E2A5E), // Intermediate color for smooth transition
              Color(0xFF243570), // Another intermediate
              Color(0xFF283593), // Indigo blue
            ],
            stops: [0.0, 0.35, 0.70, 1.0], // Gradual color stops
          ),
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
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFE8D095),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      if (isLoggedIn) 
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
            
            // Menu items
            _buildMenuItem(
              Icons.attach_money, 
              'Döviz', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/dashboard-screen');
              },
              currentRoute == '/dashboard-screen'
            ),
            
            _buildMenuItemCustomIcon(
              GoldBarsIcon(
                color: currentRoute == '/gold-coin-prices-screen' 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.9),
                size: 22,
              ), 
              'Altın', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/gold-coin-prices-screen');
              },
              currentRoute == '/gold-coin-prices-screen'
            ),
            
            _buildMenuItem(
              Icons.swap_horiz, 
              'Döviz/Altın Çevirici', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/currency-converter-screen');
              },
              currentRoute == '/currency-converter-screen'
            ),
            
            _buildMenuItem(
              Icons.notifications_active, 
              'Alarmlar', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/price-alerts-screen');
              },
              currentRoute == '/price-alerts-screen'
            ),
            
            _buildMenuItem(
              Icons.account_balance_wallet, 
              'Portföyüm', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/portfolio-management-screen');
              },
              currentRoute == '/portfolio-management-screen'
            ),
            
            _buildMenuItem(
              Icons.bookmark, 
              'Takip Listem', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/watchlist-screen');
              },
              currentRoute == '/watchlist-screen'
            ),
            
            _buildMenuItem(
              Icons.trending_up, 
              'Kar / Zarar Hesaplama', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/profit-loss-calculator-screen');
              },
              currentRoute == '/profit-loss-calculator-screen'
            ),
            
            _buildMenuItem(
              Icons.receipt_long, 
              'Performans Geçmişi', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/winners-losers-screen');
              },
              currentRoute == '/winners-losers-screen'
            ),
            
            _buildMenuItem(
              Icons.currency_exchange, 
              'Sarrafiye İşçilikleri', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/sarrafiye-iscilik-screen');
              },
              currentRoute == '/sarrafiye-iscilik-screen'
            ),
            
            _buildMenuItem(
              Icons.history, 
              'Geçmiş Kurlar', 
              () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/gecmis-kurlar-screen');
              },
              currentRoute == '/gecmis-kurlar-screen'
            ),
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
  
  Widget _buildMenuItemCustomIcon(Widget icon, String title, VoidCallback onTap, [bool isActive = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
            color: Colors.white,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
          color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
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