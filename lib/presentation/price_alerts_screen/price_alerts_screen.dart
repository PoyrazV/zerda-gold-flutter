import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/price_ticker.dart';
import './widgets/alert_card_widget.dart';
import './widgets/alert_history_widget.dart';
import './widgets/create_alert_bottom_sheet.dart';
import './widgets/empty_alerts_widget.dart';

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({Key? key}) : super(key: key);

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activeAlerts = [];
  List<Map<String, dynamic>> _historyAlerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadMockData();
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
  }

  void _updateTicker() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WatchlistService.removeListener(_updateTicker);
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mock active alerts data
    _activeAlerts = [
      {
        'id': 1,
        'assetName': 'USD/TRY',
        'assetFullName': 'Amerikan Doları',
        'targetPrice': 35.0000,
        'currentPrice': 34.2156,
        'alertType': 'above',
        'status': 'active',
        'isEnabled': true,
        'enableNotification': true,
        'soundType': 'default',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': 2,
        'assetName': 'EUR/TRY',
        'assetFullName': 'Euro',
        'targetPrice': 36.5000,
        'currentPrice': 37.1234,
        'alertType': 'below',
        'status': 'active',
        'isEnabled': true,
        'enableNotification': true,
        'soundType': 'bell',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': 3,
        'assetName': 'GOLD',
        'assetFullName': 'Altın (Gram)',
        'targetPrice': 2900.00,
        'currentPrice': 2847.50,
        'alertType': 'above',
        'status': 'active',
        'isEnabled': false,
        'enableNotification': true,
        'soundType': 'chime',
        'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
      },
      {
        'id': 4,
        'assetName': 'BTC/USD',
        'assetFullName': 'Bitcoin',
        'targetPrice': 70000.00,
        'currentPrice': 67234.50,
        'alertType': 'above',
        'status': 'active',
        'isEnabled': true,
        'enableNotification': false,
        'soundType': 'alert',
        'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
      },
    ];

    // Mock history alerts data
    _historyAlerts = [
      {
        'id': 101,
        'assetName': 'USD/TRY',
        'assetFullName': 'Amerikan Doları',
        'targetPrice': 34.0000,
        'triggeredPrice': 34.0156,
        'alertType': 'above',
        'status': 'triggered',
        'triggeredAt': DateTime.now().subtract(const Duration(days: 3)),
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'id': 102,
        'assetName': 'GOLD',
        'assetFullName': 'Altın (Gram)',
        'targetPrice': 2800.00,
        'triggeredPrice': 2795.50,
        'alertType': 'below',
        'status': 'triggered',
        'triggeredAt': DateTime.now().subtract(const Duration(days: 7)),
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      },
      {
        'id': 103,
        'assetName': 'EUR/TRY',
        'assetFullName': 'Euro',
        'targetPrice': 38.0000,
        'triggeredPrice': 37.8234,
        'alertType': 'below',
        'status': 'triggered',
        'triggeredAt': DateTime.now().subtract(const Duration(days: 14)),
        'createdAt': DateTime.now().subtract(const Duration(days: 16)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding
          const AppHeader(),
          
          // Price ticker
          _buildPriceTicker(),
          
          // Tab bar
          _buildTabBar(),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveAlertsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
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

  Widget _buildPriceTicker() {
    // Use shared PriceTicker widget
    return PriceTicker();
  }

  // Removed old ticker implementation - using shared PriceTicker widget instead
  /*
  Widget _buildPriceTickerOld() {
    // Old implementation moved to shared PriceTicker widget
    final watchlistItems = WatchlistService.getWatchlistItems();
    final tickerData = watchlistItems.isEmpty 
        ? [
            {
              'symbol': 'USD/TRY',
              'price': 34.2156,
              'change': 0.0234,
              'changePercent': 0.068
            },
          ]
        : watchlistItems.map((item) => {
            'symbol': item['code'],
            'price': item['buyPrice'],
            'change': item['change'], 
            'changePercent': item['changePercent']
          }).toList();
          
    return Column(
      children: [
        Container(
          height: 10.h,
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
          padding: EdgeInsets.only(bottom: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemCount: tickerData.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          // Add button at the end
          if (index == tickerData.length) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/asset-selection-screen');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(height: 0.2.h),
                      Text(
                        'Ekle',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final data = tickerData[index]; // Remove the % operation
          final bool isPositive = (data['change'] as double) >= 0;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    data['symbol'] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(height: 0.2.h),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          CurrencyFormatter.formatTRY(data['price'] as double, decimalPlaces: 4),
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: 0.5.w),
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive
                            ? AppTheme.positiveGreen
                            : AppTheme.negativeRed,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
          ),
        ),
      ],
    );
  }
  */

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.lightTheme.colorScheme.primary,
        labelColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    return AnimatedBuilder(
                      animation: _tabController.animation!,
                      builder: (context, child) {
                        return CustomIconWidget(
                          iconName: 'notifications_active',
                          color: _tabController.index == 0
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.textSecondaryLight,
                          size: 16,
                        );
                      },
                    );
                  },
                ),
                SizedBox(width: 1.w),
                Text(
                  'Aktif',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (_activeAlerts.isNotEmpty) ...[
                  SizedBox(width: 1.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_activeAlerts.length}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    return AnimatedBuilder(
                      animation: _tabController.animation!,
                      builder: (context, child) {
                        return CustomIconWidget(
                          iconName: 'history',
                          color: _tabController.index == 1
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.textSecondaryLight,
                          size: 16,
                        );
                      },
                    );
                  },
                ),
                SizedBox(width: 1.w),
                Text(
                  'Geçmiş',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsTab() {
    if (_activeAlerts.isEmpty) {
      return EmptyAlertsWidget(
        onCreateAlert: _showCreateAlertBottomSheet,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAlerts,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 1.h, bottom: 0.5.h),
        itemCount: _activeAlerts.length,
        itemBuilder: (context, index) {
          final alert = _activeAlerts[index];
          return AlertCardWidget(
            alertData: alert,
            onEdit: () => _editAlert(alert),
            onDuplicate: () => _duplicateAlert(alert),
            onDelete: () => _deleteAlert(alert['id'] as int),
            onToggle: () => _toggleAlert(alert['id'] as int),
            onTap: () => _showAlertDetail(alert),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 1.h, bottom: 0.5.h),
        child: AlertHistoryWidget(
          historyAlerts: _historyAlerts,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCreateAlertBottomSheet,
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      child: CustomIconWidget(
        iconName: 'add',
        color: Colors.white,
        size: 24,
      ),
    );
  }

  void _showCreateAlertBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateAlertBottomSheet(
        onCreateAlert: _createAlert,
      ),
    );
  }

  void _createAlert(Map<String, dynamic> alertData) {
    setState(() {
      _activeAlerts.insert(0, alertData);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm başarıyla oluşturuldu'),
        backgroundColor: AppTheme.positiveGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editAlert(Map<String, dynamic> alert) {
    // Navigate to edit alert screen or show edit bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm düzenleme özelliği yakında eklenecek'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _duplicateAlert(Map<String, dynamic> alert) {
    final duplicatedAlert = Map<String, dynamic>.from(alert);
    duplicatedAlert['id'] = DateTime.now().millisecondsSinceEpoch;
    duplicatedAlert['createdAt'] = DateTime.now();

    setState(() {
      _activeAlerts.insert(0, duplicatedAlert);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm kopyalandı'),
        backgroundColor: AppTheme.positiveGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteAlert(int alertId) {
    setState(() {
      _activeAlerts.removeWhere((alert) => alert['id'] == alertId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm silindi'),
        backgroundColor: AppTheme.negativeRed,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Geri Al',
          textColor: Colors.white,
          onPressed: () {
            // Implement undo functionality
          },
        ),
      ),
    );
  }

  void _toggleAlert(int alertId) {
    setState(() {
      final alertIndex =
          _activeAlerts.indexWhere((alert) => alert['id'] == alertId);
      if (alertIndex != -1) {
        _activeAlerts[alertIndex]['isEnabled'] =
            !(_activeAlerts[alertIndex]['isEnabled'] as bool);
        _activeAlerts[alertIndex]['status'] =
            (_activeAlerts[alertIndex]['isEnabled'] as bool)
                ? 'active'
                : 'disabled';
      }
    });
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
