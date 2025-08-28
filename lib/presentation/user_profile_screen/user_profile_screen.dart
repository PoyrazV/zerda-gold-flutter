import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import './widgets/logout_button_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import '../../services/auth_service.dart';
import '../../services/user_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  String _selectedTheme = "Otomatik";
  String _selectedCurrency = "TRY";
  String _selectedTimeframe = "1 Gün";
  String _selectedLanguage = "Türkçe";

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() {
    // Load preferences from local storage or API in the future
    // For now, using default values
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          ProfileHeaderWidget(
            userName: authService.userName ?? "Kullanıcı",
            userEmail: authService.userEmail ?? "email@example.com",
            avatarUrl: authService.userProfileImage,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  _buildAccountSection(),
                  _buildAppSettingsSection(),
                  _buildSupportSection(),
                  SizedBox(height: 2.h),
                  LogoutButtonWidget(
                    onLogout: _handleLogout,
                  ),
                  SizedBox(height: 2.h),
                  // Debug button to show user data
                  ElevatedButton.icon(
                    onPressed: _showUserData,
                    icon: Icon(Icons.bug_report),
                    label: Text('Kullanıcı Verilerini Göster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return SettingsSectionWidget(
      title: 'Hesap Bilgileri',
      items: [
        SettingsItem(
          title: 'Profili Düzenle',
          subtitle: 'Kişisel bilgilerinizi güncelleyin',
          iconName: 'edit',
          onTap: _editProfile,
        ),
        SettingsItem(
          title: 'Şifre Değiştir',
          subtitle: 'Hesap güvenliğinizi artırın',
          iconName: 'lock',
          onTap: _changePassword,
        ),
      ],
    );
  }

  Widget _buildAppSettingsSection() {
    return SettingsSectionWidget(
      title: 'Uygulama Ayarları',
      items: [
        SettingsItem(
          title: 'Bildirimler',
          subtitle: _notificationsEnabled ? 'Açık' : 'Kapalı',
          iconName: 'notifications',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeColor: ThemeConfigService().primaryColor,
            activeTrackColor: ThemeConfigService().primaryColor.withOpacity(0.5),
            inactiveThumbColor: Colors.grey[500],
            inactiveTrackColor: Colors.grey[300],
            trackOutlineColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF5A6491);
              }
              return Colors.grey[400];
            }),
          ),
          showDisclosure: false,
        ),
        SettingsItem(
          title: 'Ses Bildirimleri',
          subtitle: _soundEnabled ? 'Açık' : 'Kapalı',
          iconName: 'volume_up',
          trailing: Switch(
            value: _soundEnabled,
            onChanged: _toggleSound,
            activeColor: ThemeConfigService().primaryColor,
            activeTrackColor: ThemeConfigService().primaryColor.withOpacity(0.5),
            inactiveThumbColor: Colors.grey[500],
            inactiveTrackColor: Colors.grey[300],
            trackOutlineColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF5A6491);
              }
              return Colors.grey[400];
            }),
          ),
          showDisclosure: false,
        ),
        SettingsItem(
          title: 'Para Birimi',
          subtitle: _selectedCurrency,
          iconName: 'attach_money',
          onTap: _selectCurrency,
        ),
        SettingsItem(
          title: 'Dil',
          subtitle: _selectedLanguage,
          iconName: 'language',
          onTap: _selectLanguage,
        ),
      ],
    );
  }


  Widget _buildSupportSection() {
    return SettingsSectionWidget(
      title: 'Destek',
      items: [
        SettingsItem(
          title: 'İletişim',
          subtitle: 'Destek ekibiyle iletişime geçin',
          iconName: 'contact_support',
          onTap: _contactSupport,
        ),
        SettingsItem(
          title: 'Uygulamayı Değerlendir',
          subtitle: 'App Store\'da değerlendirin',
          iconName: 'star',
          onTap: _rateApp,
        ),
        SettingsItem(
          title: 'Gizlilik Politikası',
          subtitle: 'Veri kullanım koşulları',
          iconName: 'privacy_tip',
          onTap: _privacyPolicy,
        ),
      ],
    );
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    _showSettingChangedSnackBar(
        'Bildirimler ${value ? 'açıldı' : 'kapatıldı'}');
  }

  void _toggleSound(bool value) {
    setState(() {
      _soundEnabled = value;
    });
    _showSettingChangedSnackBar(
        'Ses bildirimleri ${value ? 'açıldı' : 'kapatıldı'}');
  }

  void _toggleHaptic(bool value) {
    setState(() {
      _hapticEnabled = value;
    });
    _showSettingChangedSnackBar(
        'Haptic geri bildirim ${value ? 'açıldı' : 'kapatıldı'}');
  }

  void _selectCurrency() {
    _showSelectionBottomSheet(
      title: 'Para Birimi Seçin',
      options: ['TRY', 'USD', 'EUR', 'GBP'],
      currentSelection: _selectedCurrency,
      onSelected: (value) {
        setState(() {
          _selectedCurrency = value;
        });
        _showSettingChangedSnackBar('Para birimi $value olarak değiştirildi');
      },
    );
  }

  void _selectTimeframe() {
    _showSelectionBottomSheet(
      title: 'Grafik Zaman Dilimi',
      options: ['1 Saat', '1 Gün', '1 Hafta', '1 Ay', '3 Ay', '1 Yıl'],
      currentSelection: _selectedTimeframe,
      onSelected: (value) {
        setState(() {
          _selectedTimeframe = value;
        });
        _showSettingChangedSnackBar(
            'Grafik zaman dilimi $value olarak değiştirildi');
      },
    );
  }

  void _selectTheme() {
    _showSelectionBottomSheet(
      title: 'Tema Seçin',
      options: ['Açık', 'Koyu', 'Otomatik'],
      currentSelection: _selectedTheme,
      onSelected: (value) {
        setState(() {
          _selectedTheme = value;
        });
        _showSettingChangedSnackBar('Tema $value olarak değiştirildi');
      },
    );
  }

  void _selectLanguage() {
    _showSelectionBottomSheet(
      title: 'Dil Seçin',
      options: ['Türkçe', 'English'],
      currentSelection: _selectedLanguage,
      onSelected: (value) {
        setState(() {
          _selectedLanguage = value;
        });
        _showSettingChangedSnackBar('Dil $value olarak değiştirildi');
      },
    );
  }

  void _showSelectionBottomSheet({
    required String title,
    required List<String> options,
    required String currentSelection,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              ...options.map((option) => ListTile(
                    title: Text(
                      option,
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                    ),
                    trailing: currentSelection == option
                        ? CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 5.w,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(option);
                    },
                  )),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  void _showSettingChangedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.pushNamed(context, '/edit-profile-screen');
  }

  void _changePassword() {
    Navigator.pushNamed(context, '/change-password-screen');
  }

  void _exportPortfolioData() {
    _showSettingChangedSnackBar('Portföy verileri dışa aktarılıyor...');
  }

  void _clearCache() {
    _showSettingChangedSnackBar('Önbellek temizlendi');
  }

  void _backupSettings() {
    _showComingSoonDialog('Yedekleme Ayarları');
  }

  void _helpCenter() {
    _showComingSoonDialog('Yardım Merkezi');
  }

  void _contactSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'İletişim',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: Icon(
                  Icons.phone,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Telefon'),
                subtitle: Text('+90 212 555 0123'),
                onTap: () {
                  Navigator.pop(context);
                  _showSettingChangedSnackBar('Telefon uygulaması açılıyor...');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.email,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('E-posta'),
                subtitle: Text('destek@zerda.com'),
                onTap: () {
                  Navigator.pop(context);
                  _showSettingChangedSnackBar('E-posta uygulaması açılıyor...');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.chat,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('WhatsApp'),
                subtitle: Text('+90 555 123 4567'),
                onTap: () {
                  Navigator.pop(context);
                  _showSettingChangedSnackBar('WhatsApp açılıyor...');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.web,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Web Sitesi'),
                subtitle: Text('www.zerda.com'),
                onTap: () {
                  Navigator.pop(context);
                  _showSettingChangedSnackBar('Web sitesi açılıyor...');
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  void _rateApp() {
    _showSettingChangedSnackBar('App Store açılıyor...');
  }

  void _privacyPolicy() {
    _showComingSoonDialog('Gizlilik Politikası');
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'info',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              feature,
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Bu özellik yakında kullanıma sunulacak.',
          style: AppTheme.lightTheme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showUserData() async {
    try {
      final authService = AuthService();
      final userDataService = UserDataService();
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user info
      final userId = authService.userId;
      final userEmail = authService.userEmail;
      
      // Get watchlist
      final watchlist = userDataService.getWatchlistItems();
      final watchlistString = watchlist.map((item) => '${item['code']} - ${item['name']}').join('\n');
      
      // Get portfolio
      final portfolio = userDataService.portfolio;
      final portfolioString = portfolio.map((item) => 
        '${item['assetName'] ?? item['assetCode']} - Miktar: ${item['quantity']} - Fiyat: ${item['purchasePrice']}').join('\n');
      
      // Get alerts
      final activeAlerts = userDataService.activeAlerts;
      final alertsString = activeAlerts.map((alert) => 
        '${alert['assetName'] ?? alert['assetCode']} - Hedef: ${alert['targetPrice']}').join('\n');
      
      // Also get raw from SharedPreferences
      final watchlistKey = 'user_${userId}_watchlist';
      final portfolioKey = 'user_${userId}_portfolio';
      final alertsKey = 'user_${userId}_active_alerts';
      
      final rawWatchlist = prefs.getString(watchlistKey) ?? 'Veri yok';
      final rawPortfolio = prefs.getString(portfolioKey) ?? 'Veri yok';
      final rawAlerts = prefs.getString(alertsKey) ?? 'Veri yok';
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Kullanıcı Verileri'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kullanıcı: $userEmail', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('User ID: $userId\n'),
                
                Text('TAKİP LİSTESİ (${watchlist.length} varlık):', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(watchlistString.isEmpty ? 'Boş' : watchlistString),
                Divider(),
                
                Text('PORTFÖY (${portfolio.length} pozisyon):', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(portfolioString.isEmpty ? 'Boş' : portfolioString),
                Divider(),
                
                Text('ALARMLAR (${activeAlerts.length} aktif):', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(alertsString.isEmpty ? 'Boş' : alertsString),
                Divider(),
                
                Text('SharedPreferences Keys:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Watchlist Key: $watchlistKey'),
                Text('Portfolio Key: $portfolioKey'),
                Text('Alerts Key: $alertsKey'),
                Divider(),
                
                Text('Raw Data (ilk 200 karakter):', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Watchlist: ${rawWatchlist.length > 200 ? rawWatchlist.substring(0, 200) + '...' : rawWatchlist}'),
                Text('Portfolio: ${rawPortfolio.length > 200 ? rawPortfolio.substring(0, 200) + '...' : rawPortfolio}'),
                Text('Alerts: ${rawAlerts.length > 200 ? rawAlerts.substring(0, 200) + '...' : rawAlerts}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Kapat'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri gösterilirken hata: $e')),
        );
      }
    }
  }

  void _handleLogout() async {
    try {
      print('🚪 UserProfile: Starting logout...');
      
      // Use singleton instance instead of Provider
      final authService = AuthService();
      await authService.logout();
      
      print('✅ UserProfile: Logout successful');
      
      // Check if widget is still mounted before navigation
      if (!mounted) return;
      
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login-screen',
        (route) => false,
      );
    } catch (e) {
      print('❌ UserProfile: Logout error: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
