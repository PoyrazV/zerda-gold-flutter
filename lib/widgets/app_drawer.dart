import 'package:flutter/material.dart';
import 'gold_bars_icon.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Auto-detect current route
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A148C), // Deep purple
              Color(0xFF6A1B9A), // Purple
              Color(0xFF8E24AA), // Light purple
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
            // Header with login button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ZERDA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
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
              'Döviz Çevirici', 
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
              'Kazananlar Kaybedenler', 
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
                    fontSize: 16,
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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