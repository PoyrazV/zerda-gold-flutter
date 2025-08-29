import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_data_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/ticker_section.dart';
import './widgets/alert_card_widget.dart';
import './widgets/alert_history_widget.dart';
import './widgets/alarm_asset_selection_modal.dart';
import './widgets/asset_detail_modal.dart';
import './widgets/empty_alerts_widget.dart';

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({Key? key}) : super(key: key);

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  final UserDataService _userDataService = UserDataService();
  List<Map<String, dynamic>> _activeAlerts = [];
  List<Map<String, dynamic>> _historyAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadStoredData();
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
    
    // Listen to user data changes
    _userDataService.addListener(_onUserDataChanged);
  }

  void _updateTicker() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WatchlistService.removeListener(_updateTicker);
    _userDataService.removeListener(_onUserDataChanged);
    super.dispose();
  }
  
  void _onUserDataChanged() {
    if (mounted) {
      setState(() {
        _activeAlerts = List.from(_userDataService.activeAlerts);
        _historyAlerts = List.from(_userDataService.historyAlerts);
      });
    }
  }

  Future<void> _loadStoredData() async {
    try {
      // Load from user data service
      setState(() {
        _activeAlerts = List.from(_userDataService.activeAlerts);
        _historyAlerts = List.from(_userDataService.historyAlerts);
      });
      print('Alerts: Loaded ${_activeAlerts.length} active and ${_historyAlerts.length} history alerts from user data');
    } catch (e) {
      print('Error loading stored alerts: $e');
      // Initialize empty lists on error
      _activeAlerts = [];
      _historyAlerts = [];
    }
  }

  Future<void> _saveStoredData() async {
    try {
      // Save through user data service
      await _userDataService.saveAlerts(
        activeAlerts: _activeAlerts,
        historyAlerts: _historyAlerts,
      );
      print('Alerts: Saved ${_activeAlerts.length} active and ${_historyAlerts.length} history alerts to user data');
    } catch (e) {
      print('Error saving stored alerts: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm kaydedilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding and + icon
          DashboardHeader(
            rightWidget: IconButton(
              onPressed: _showAssetSelectionModal,
              icon: Icon(
                Icons.add,
                color: Colors.white,
                size: 8.w,
              ),
              padding: EdgeInsets.all(2.w),
            ),
          ),
          
          // Spacer between logo and ticker
          Container(
            decoration: BoxDecoration(
              color: ThemeConfigService().primaryColor, // Dynamic primary color
            ),
          ),
          
          // Price ticker with API data
          const TickerSection(),
          
          // Content - show only active alerts
          Expanded(
            child: _buildActiveAlertsTab(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 12.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Stack(
            children: [
              // Left side - Menu button
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Builder(
                  builder: (context) => IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.all(2.w),
                  ),
                ),
              ),

              // Center - ZERDA title (perfectly centered)
              Center(
                child: Text(
                  'ZERDA',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20.sp,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Right side - Filter button
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  onPressed: _showFilterOptions,
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 24,
                  ),
                  padding: EdgeInsets.all(2.w),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildActiveAlertsTab() {
    if (_activeAlerts.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: EmptyAlertsWidget(
          onCreateAlert: _showAssetSelectionModal,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAlerts,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 1.h, bottom: 1.h),
        itemCount: _activeAlerts.length,
        itemBuilder: (context, index) {
          try {
            final alert = _activeAlerts[index];
            // Ensure required fields have default values
            final alertId = alert['id'] ?? DateTime.now().millisecondsSinceEpoch;
            
            return AlertCardWidget(
              alertData: alert,
              onEdit: () => _editAlert(alert),
              onDuplicate: () => _duplicateAlert(alert),
              onDelete: () async => await _deleteAlert(alertId as int),
              onToggle: () => _toggleAlert(alertId as int),
              onTap: () => _showAlertDetail(alert),
            );
          } catch (e) {
            print('Error rendering alert at index $index: $e');
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Text(
                'Error loading alert',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyAlerts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshHistory,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 60.h,
            child: AlertHistoryWidget(
              historyAlerts: _historyAlerts,
              onDelete: (alert) async => await _deleteHistoryAlert(alert),
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 1.h, bottom: 0.5.h),
        child: AlertHistoryWidget(
          historyAlerts: _historyAlerts,
          onDelete: (alert) async => await _deleteHistoryAlert(alert),
        ),
      ),
    );
  }


  void _showAssetSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AlarmAssetSelectionModal(
        onAssetSelected: _onAssetSelected,
      ),
    );
  }

  void _onAssetSelected(Map<String, dynamic> selectedAsset) {
    print('_onAssetSelected called with: $selectedAsset');
    // Wait a bit for the first modal to close, then show asset detail modal
    Future.delayed(const Duration(milliseconds: 300), () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AssetDetailModal(
          selectedAsset: selectedAsset,
          onCreateAlarm: _createAlarmWithPrice,
        ),
      );
    });
  }

  void _createAlarmWithPrice(Map<String, dynamic> selectedAsset, double targetPrice) {
    final alertData = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'assetCode': selectedAsset['code'],
      'assetName': selectedAsset['name'], 
      'targetPrice': targetPrice,
      'currentPrice': selectedAsset['currentPrice'] ?? 0.0,
      'status': 'active',  // active veya disabled olacak
      'createdAt': DateTime.now().toIso8601String(),  // Convert to string for storage
    };

    _createAlert(alertData);
  }

  void _createAlert(Map<String, dynamic> alertData) {
    setState(() {
      _activeAlerts.insert(0, alertData);
    });
    
    // Save to persistent storage
    _saveStoredData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm başarıyla oluşturuldu'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editAlert(Map<String, dynamic> alert) {
    // Format alert data for asset detail modal
    final selectedAsset = {
      'code': alert['assetCode'] ?? alert['assetName'] ?? '',
      'name': alert['assetName'] ?? '',
      'currentPrice': alert['currentPrice'] ?? 0.0,
    };

    // Show asset detail modal for editing
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssetDetailModal(
        selectedAsset: selectedAsset,
        initialTargetPrice: alert['targetPrice'] as double,
        onCreateAlarm: (asset, targetPrice) => _updateAlarmWithPrice(alert['id'], asset, targetPrice),
      ),
    );
  }

  void _updateAlarmWithPrice(int alertId, Map<String, dynamic> selectedAsset, double targetPrice) {
    setState(() {
      final alertIndex = _activeAlerts.indexWhere((alert) => alert['id'] == alertId);
      if (alertIndex != -1) {
        _activeAlerts[alertIndex]['targetPrice'] = targetPrice;
        _activeAlerts[alertIndex]['currentPrice'] = selectedAsset['currentPrice'];
      }
    });
    
    // Save to persistent storage
    _saveStoredData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm başarıyla güncellendi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _duplicateAlert(Map<String, dynamic> alert) {
    // Sadece gerekli alanları kopyala
    final duplicatedAlert = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'assetCode': alert['assetCode'] ?? alert['assetName'] ?? '',
      'assetName': alert['assetName'] ?? '',
      'targetPrice': alert['targetPrice'] ?? 0.0,
      'currentPrice': alert['currentPrice'] ?? 0.0,
      'status': 'active',  // Yeni kopyalar aktif olarak başlar
      'createdAt': DateTime.now().toIso8601String(),  // Convert to string for storage
    };

    setState(() {
      _activeAlerts.insert(0, duplicatedAlert);
    });
    
    // Save to persistent storage
    _saveStoredData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm kopyalandı'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteHistoryAlert(Map<String, dynamic> alert) async {
    // Store for potential restoration
    final deletedIndex = _historyAlerts.indexWhere((item) => item['id'] == alert['id']);
    if (deletedIndex == -1) return;
    
    final deletedAlert = Map<String, dynamic>.from(_historyAlerts[deletedIndex]);
    
    setState(() {
      _historyAlerts.removeWhere((item) => item['id'] == alert['id']);
    });
    
    try {
      await _saveStoredData();
      print('✅ History alert deleted successfully: ID ${alert['id']}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geçmiş alarm silindi'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting history alert: $e');
      // Restore if save failed
      if (mounted) {
        setState(() {
          _historyAlerts.insert(deletedIndex, deletedAlert);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geçmiş alarm silinemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAlert(int alertId) async {
    // Store the deleted alert for undo functionality
    final deletedIndex = _activeAlerts.indexWhere((alert) => alert['id'] == alertId);
    if (deletedIndex == -1) return;
    
    final deletedAlert = Map<String, dynamic>.from(_activeAlerts[deletedIndex]);
    
    // Remove from state immediately for responsive UI
    setState(() {
      _activeAlerts.removeWhere((alert) => alert['id'] == alertId);
    });
    
    // Save to persistent storage and wait for completion
    try {
      await _saveStoredData();
      print('✅ Alert deleted successfully: ID $alertId');
      
      // Show success message only after successful save
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm silindi'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Geri Al',
              textColor: Colors.white,
              onPressed: () async {
                setState(() {
                  _activeAlerts.insert(deletedIndex, deletedAlert);
                });
                // Also await the undo save operation
                await _saveStoredData();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting alert: $e');
      // Restore the alert if save failed
      if (mounted) {
        setState(() {
          _activeAlerts.insert(deletedIndex, deletedAlert);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm silinemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleAlert(int alertId) {
    setState(() {
      final alertIndex = _activeAlerts.indexWhere((alert) => alert['id'] == alertId);
      if (alertIndex != -1) {
        final currentStatus = _activeAlerts[alertIndex]['status'] ?? 'active';
        _activeAlerts[alertIndex]['status'] = 
            currentStatus == 'active' ? 'disabled' : 'active';
      }
    });
    
    // Save to persistent storage
    _saveStoredData();
  }

  void _showAlertDetail(Map<String, dynamic> alert) {
    Navigator.pushNamed(context, '/asset-detail-screen');
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtrele',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'notifications_active',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text('Sadece Aktif Alarmlar'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'trending_up',
                color: AppTheme.positiveGreen,
                size: 24,
              ),
              title: Text('Fiyat Üstü Alarmları'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'trending_down',
                color: AppTheme.negativeRed,
                size: 24,
              ),
              title: Text('Fiyat Altı Alarmları'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // Settings menu - Temporarily disabled
  // void _showSettingsMenu() {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => Container(
  //       padding: EdgeInsets.all(4.w),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             'Alarm Ayarları',
  //             style: AppTheme.lightTheme.textTheme.titleLarge,
  //           ),
  //           SizedBox(height: 2.h),
  //           ListTile(
  //             leading: CustomIconWidget(
  //               iconName: 'volume_up',
  //               color: AppTheme.lightTheme.colorScheme.primary,
  //               size: 24,
  //             ),
  //             title: Text('Bildirim Sesleri'),
  //             onTap: () => Navigator.pop(context),
  //           ),
  //           ListTile(
  //             leading: CustomIconWidget(
  //               iconName: 'schedule',
  //               color: AppTheme.lightTheme.colorScheme.primary,
  //               size: 24,
  //             ),
  //             title: Text('Çalışma Saatleri'),
  //             onTap: () => Navigator.pop(context),
  //           ),
  //           ListTile(
  //             leading: CustomIconWidget(
  //               iconName: 'backup',
  //               color: AppTheme.lightTheme.colorScheme.primary,
  //               size: 24,
  //             ),
  //             title: Text('Alarmları Dışa Aktar'),
  //             onTap: () => Navigator.pop(context),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<void> _refreshAlerts() async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulate price updates
    setState(() {
      for (var alert in _activeAlerts) {
        final currentPrice = (alert['currentPrice'] as double);
        final change = (currentPrice * 0.001) *
            (DateTime.now().millisecond % 2 == 0 ? 1 : -1);
        alert['currentPrice'] = currentPrice + change;
      }
    });
  }

  Future<void> _refreshHistory() async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulate history refresh
  }Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/price-alerts-screen');
  }
}
