import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({Key? key}) : super(key: key);

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Döviz kıymetleri listesi
  final List<Map<String, dynamic>> _currencyData = [
    {
      'code': 'USD/TRY',
      'name': 'Amerikan Doları',
      'buyPrice': 34.2156,
      'sellPrice': 34.2456,
      'change': 0.0234,
      'changePercent': 0.068,
      'isPositive': true,
    },
    {
      'code': 'EUR/TRY',
      'name': 'Euro',
      'buyPrice': 37.1234,
      'sellPrice': 37.1534,
      'change': -0.0456,
      'changePercent': -0.123,
      'isPositive': false,
    },
    {
      'code': 'GBP/TRY',
      'name': 'İngiliz Sterlini',
      'buyPrice': 43.5678,
      'sellPrice': 43.5978,
      'change': 0.1234,
      'changePercent': 0.284,
      'isPositive': true,
    },
    {
      'code': 'CHF/TRY',
      'name': 'İsviçre Frangı',
      'buyPrice': 38.4567,
      'sellPrice': 38.4867,
      'change': -0.0234,
      'changePercent': -0.061,
      'isPositive': false,
    },
    {
      'code': 'CAD/TRY',
      'name': 'Kanada Doları',
      'buyPrice': 25.1234,
      'sellPrice': 25.1534,
      'change': 0.0567,
      'changePercent': 0.226,
      'isPositive': true,
    },
    {
      'code': 'AUD/TRY',
      'name': 'Avustralya Doları',
      'buyPrice': 22.7890,
      'sellPrice': 22.8190,
      'change': -0.0123,
      'changePercent': -0.054,
      'isPositive': false,
    },
    {
      'code': 'JPY/TRY',
      'name': 'Japon Yeni',
      'buyPrice': 0.2345,
      'sellPrice': 0.2365,
      'change': 0.0012,
      'changePercent': 0.515,
      'isPositive': true,
    },
    {
      'code': 'SEK/TRY',
      'name': 'İsveç Kronu',
      'buyPrice': 3.1234,
      'sellPrice': 3.1334,
      'change': -0.0045,
      'changePercent': -0.144,
      'isPositive': false,
    },
  ];

  // Altın kıymetleri listesi
  final List<Map<String, dynamic>> _goldData = [
    {
      'code': 'GRAM',
      'name': 'Gram Altın',
      'buyPrice': 2640.50,
      'sellPrice': 2654.30,
      'change': 0.65,
      'changePercent': 0.025,
      'isPositive': true,
    },
    {
      'code': 'YÇEYREK',
      'name': 'Yeni Çeyrek Altın',
      'buyPrice': 2876.50,
      'sellPrice': 2891.75,
      'change': 0.85,
      'changePercent': 0.030,
      'isPositive': true,
    },
    {
      'code': 'EÇEYREK',
      'name': 'Eski Çeyrek Altın',
      'buyPrice': 2845.25,
      'sellPrice': 2860.40,
      'change': -0.45,
      'changePercent': -0.016,
      'isPositive': false,
    },
    {
      'code': 'YYARIM',
      'name': 'Yeni Yarım Altın',
      'buyPrice': 5753.00,
      'sellPrice': 5783.50,
      'change': 1.12,
      'changePercent': 0.019,
      'isPositive': true,
    },
    {
      'code': 'EYARIM',
      'name': 'Eski Yarım Altın',
      'buyPrice': 5690.75,
      'sellPrice': 5720.80,
      'change': -0.28,
      'changePercent': -0.005,
      'isPositive': false,
    },
    {
      'code': 'YTAM',
      'name': 'Yeni Tam Altın',
      'buyPrice': 11506.00,
      'sellPrice': 11567.00,
      'change': 0.95,
      'changePercent': 0.008,
      'isPositive': true,
    },
    {
      'code': 'ETAM',
      'name': 'Eski Tam Altın',
      'buyPrice': 11381.50,
      'sellPrice': 11441.60,
      'change': -0.62,
      'changePercent': -0.005,
      'isPositive': false,
    },
    {
      'code': 'CUMHUR',
      'name': 'Cumhuriyet Altını',
      'buyPrice': 11548.90,
      'sellPrice': 11610.30,
      'change': 0.78,
      'changePercent': 0.007,
      'isPositive': true,
    },
    {
      'code': 'GUMUS',
      'name': 'Gümüş (Gram)',
      'buyPrice': 33.45,
      'sellPrice': 34.25,
      'change': -0.45,
      'changePercent': -0.013,
      'isPositive': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    _refreshController.forward();

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kıymetler güncellendi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addToWatchlist(Map<String, dynamic> asset) {
    WatchlistService.addToWatchlist(asset);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${asset['name']} eklendi',
          style: TextStyle(fontSize: 12.sp),
        ),
        backgroundColor: AppTheme.positiveGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: 4.w,
          right: 4.w,
        ),
      ),
    );
    
    // Trigger rebuild to update the UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: Column(
          children: [
            // Header with ZERDA branding
            _buildHeader(),

            // Tab bar
            _buildTabBar(),

            // Main content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCurrencyTab(),
                  _buildGoldTab(),
                ],
              ),
            ),
          ],
        ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.all(2.w),
              ),

              // Title
              Text(
                'Kıymet Ekle',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space for symmetry
              SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Döviz',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Altın',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _currencyData.length,
      itemBuilder: (context, index) {
        final currency = _currencyData[index];
        final isLastItem = index == _currencyData.length - 1;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            border: isLastItem ? null : Border(
              bottom: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: _buildAssetRow(currency),
        );
      },
    );
  }

  Widget _buildGoldTab() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _goldData.length,
      itemBuilder: (context, index) {
        final gold = _goldData[index];
        final isLastItem = index == _goldData.length - 1;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            border: isLastItem ? null : Border(
              bottom: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: _buildAssetRow(gold),
        );
      },
    );
  }

  Widget _buildAssetRow(Map<String, dynamic> asset) {
    final bool isPositive = asset['isPositive'] as bool;
    final bool isInWatchlist = WatchlistService.isInWatchlist(asset['code'] as String);

    return InkWell(
      onTap: () {
        if (!isInWatchlist) {
          _addToWatchlist(asset);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Zaten eklendi',
                style: TextStyle(fontSize: 12.sp),
              ),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
              margin: EdgeInsets.only(
                bottom: 12.h,
                left: 4.w,
                right: 4.w,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 1.5.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Asset info
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    asset['code'] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.2.h),
                  Text(
                    asset['name'] as String,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Price and change
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.formatTRY(asset['buyPrice'] as double, decimalPlaces: 4),
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.2.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
                        size: 12,
                      ),
                      SizedBox(width: 0.5.w),
                      Text(
                        CurrencyFormatter.formatPercentageChange(asset['changePercent'] as double),
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Add button or added indicator
            SizedBox(width: 3.w),
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: isInWatchlist 
                    ? AppTheme.positiveGreen 
                    : AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInWatchlist ? Icons.check : Icons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/add-asset-screen');
  }

  Widget _buildBottomNavigation_OLD() {
    final List<Map<String, dynamic>> navItems = [
      {
        'title': 'Döviz',
        'icon': Icons.attach_money,
        'route': '/dashboard-screen',
      },
      {
        'title': 'Altın',
        'icon': Icons.star,
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

    return Container(
      height: 8.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = false; // No active state for this screen

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, item['route'] as String);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.w,
                    vertical: 0.3.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isActive
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      SizedBox(height: 0.2.h),
                      Text(
                        item['title'] as String,
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 8.sp,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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