import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class EmailPreferencesScreen extends StatefulWidget {
  const EmailPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<EmailPreferencesScreen> createState() => _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState extends State<EmailPreferencesScreen> {
  // Email preference settings
  bool _marketUpdates = true;
  bool _priceAlerts = true;
  bool _portfolioSummary = true;
  bool _newsletters = false;
  bool _promotions = false;
  bool _systemNotifications = true;
  bool _securityAlerts = true;
  
  String _emailFrequency = 'Günlük';
  String _alertThreshold = '%5';
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  void _loadCurrentPreferences() {
    // Mock current preferences - in real app, load from backend/storage
    // Current values are already set in initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        title: Text(
          'E-posta Tercihleri',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'E-posta Bildirimleri',
                            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Hangi konularda e-posta almak istediğinizi seçebilirsiniz.',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              // Financial Notifications Section
              _buildSectionHeader('Finansal Bildirimler'),
              SizedBox(height: 2.h),

              _buildSwitchTile(
                title: 'Piyasa Güncellemeleri',
                subtitle: 'Günlük piyasa özetleri ve analizleri',
                value: _marketUpdates,
                onChanged: (value) {
                  setState(() {
                    _marketUpdates = value;
                  });
                },
                icon: Icons.trending_up,
              ),

              _buildSwitchTile(
                title: 'Fiyat Alarmları',
                subtitle: 'Belirlediğiniz fiyat seviyelerine ulaşıldığında',
                value: _priceAlerts,
                onChanged: (value) {
                  setState(() {
                    _priceAlerts = value;
                  });
                },
                icon: Icons.notifications_active,
              ),

              _buildSwitchTile(
                title: 'Portföy Özeti',
                subtitle: 'Portföy performansı ve değişimler',
                value: _portfolioSummary,
                onChanged: (value) {
                  setState(() {
                    _portfolioSummary = value;
                  });
                },
                icon: Icons.pie_chart,
              ),

              SizedBox(height: 3.h),

              // Marketing Section
              _buildSectionHeader('Pazarlama'),
              SizedBox(height: 2.h),

              _buildSwitchTile(
                title: 'Bülten',
                subtitle: 'Haftalık finansal haberler ve öneriler',
                value: _newsletters,
                onChanged: (value) {
                  setState(() {
                    _newsletters = value;
                  });
                },
                icon: Icons.newspaper,
              ),

              _buildSwitchTile(
                title: 'Promosyonlar',
                subtitle: 'Özel teklifler ve kampanyalar',
                value: _promotions,
                onChanged: (value) {
                  setState(() {
                    _promotions = value;
                  });
                },
                icon: Icons.local_offer,
              ),

              SizedBox(height: 3.h),

              // System Notifications Section
              _buildSectionHeader('Sistem Bildirimleri'),
              SizedBox(height: 2.h),

              _buildSwitchTile(
                title: 'Sistem Bildirimleri',
                subtitle: 'Uygulama güncellemeleri ve bakım bildirimleri',
                value: _systemNotifications,
                onChanged: (value) {
                  setState(() {
                    _systemNotifications = value;
                  });
                },
                icon: Icons.system_update,
              ),

              _buildSwitchTile(
                title: 'Güvenlik Uyarıları',
                subtitle: 'Hesap güvenliği ve şüpheli aktiviteler',
                value: _securityAlerts,
                onChanged: (value) {
                  setState(() {
                    _securityAlerts = value;
                  });
                },
                icon: Icons.security,
              ),

              SizedBox(height: 3.h),

              // Settings Section
              _buildSectionHeader('Ayarlar'),
              SizedBox(height: 2.h),

              _buildSelectionTile(
                title: 'E-posta Sıklığı',
                subtitle: _emailFrequency,
                onTap: () => _selectEmailFrequency(),
                icon: Icons.schedule,
              ),

              _buildSelectionTile(
                title: 'Fiyat Alarm Eşiği',
                subtitle: _alertThreshold + ' değişim',
                onTap: () => _selectAlertThreshold(),
                icon: Icons.tune,
              ),

              SizedBox(height: 6.h),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 5.w,
                          height: 5.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'Kaydet',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 2.h),

              // Reset to Default Button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _resetToDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                    side: BorderSide(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Varsayılan Ayarlara Dön',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
        color: AppTheme.lightTheme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 6.w,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.lightTheme.colorScheme.surface,
      ),
    );
  }

  void _selectEmailFrequency() {
    _showSelectionBottomSheet(
      title: 'E-posta Sıklığı',
      options: ['Anında', 'Günlük', 'Haftalık', 'Aylık'],
      currentSelection: _emailFrequency,
      onSelected: (value) {
        setState(() {
          _emailFrequency = value;
        });
      },
    );
  }

  void _selectAlertThreshold() {
    _showSelectionBottomSheet(
      title: 'Fiyat Alarm Eşiği',
      options: ['%1', '%2', '%5', '%10', '%15'],
      currentSelection: _alertThreshold,
      onSelected: (value) {
        setState(() {
          _alertThreshold = value;
        });
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
                        ? Icon(
                            Icons.check,
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

  void _resetToDefault() {
    setState(() {
      _marketUpdates = true;
      _priceAlerts = true;
      _portfolioSummary = true;
      _newsletters = false;
      _promotions = false;
      _systemNotifications = true;
      _securityAlerts = true;
      _emailFrequency = 'Günlük';
      _alertThreshold = '%5';
    });
    _showSnackBar('Ayarlar varsayılan değerlere sıfırlandı');
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Success haptic feedback
      HapticFeedback.lightImpact();

      if (mounted) {
        _showSnackBar('E-posta tercihleri başarıyla kaydedildi');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Ayarlar kaydedilirken bir hata oluştu', isError: true);
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? AppTheme.lightTheme.colorScheme.error 
            : AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}