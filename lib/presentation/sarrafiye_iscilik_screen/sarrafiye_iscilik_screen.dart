import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';

class SarrafiyeIscilikScreen extends StatefulWidget {
  const SarrafiyeIscilikScreen({Key? key}) : super(key: key);

  @override
  State<SarrafiyeIscilikScreen> createState() => _SarrafiyeIscilikScreenState();
}

class _SarrafiyeIscilikScreenState extends State<SarrafiyeIscilikScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Sarrafiye işçilik fiyatları
  final List<Map<String, dynamic>> _iscilikData = [
    {
      'name': 'Yeni Çeyrek',
      'buyPrice': 1.6300,
      'sellPrice': 1.6350,
    },
    {
      'name': 'Eski Çeyrek', 
      'buyPrice': 1.5970,
      'sellPrice': 1.6050,
    },
    {
      'name': 'Yeni Yarım',
      'buyPrice': 3.2600,
      'sellPrice': 3.2700,
    },
    {
      'name': 'Eski Yarım',
      'buyPrice': 3.1900,
      'sellPrice': 3.2050,
    },
    {
      'name': 'Yeni Tam',
      'buyPrice': 6.5000,
      'sellPrice': 6.5100,
    },
    {
      'name': 'Eski Tam',
      'buyPrice': 6.3980,
      'sellPrice': 6.4100,
    },
    {
      'name': 'Yeni Gremese',
      'buyPrice': 16.1900,
      'sellPrice': 16.2500,
    },
    {
      'name': 'Eski Gremese',
      'buyPrice': 15.9500,
      'sellPrice': 16.1000,
    },
    {
      'name': 'Yeni Ata',
      'buyPrice': 6.6000,
      'sellPrice': 6.6700,
    },
    {
      'name': 'Eski Ata',
      'buyPrice': 6.6000,
      'sellPrice': 6.6100,
    },
    {
      'name': 'Yeni Ata5',
      'buyPrice': 33.2500,
      'sellPrice': 33.3500,
    },
    {
      'name': 'Eski Ata5',
      'buyPrice': 33.1000,
      'sellPrice': 33.2000,
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
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
    _refreshController.dispose();
    WatchlistService.removeListener(_updateTicker);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    _refreshController.forward();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sarrafiye işçilikleri güncellendi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: Column(
          children: [
            // Header with ZERDA branding
            _buildHeader(),

            // Price ticker
            _buildPriceTicker(),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    
                    // Header section with table headers
                    _buildTableHeader(),

                    // Sarrafiye işçilik list
                    _buildSarrafiyeList(),

                    SizedBox(height: 2.h),
                  ],
                ),
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
              // Menu button (hamburger)
              Builder(
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

              // Title
              Text(
                'Sarrafiye İşçilikleri',
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

  Widget _buildPriceTicker() {
    // Show watchlist items in ticker
    final watchlistItems = WatchlistService.getWatchlistItems();
    final tickerData = watchlistItems.isEmpty 
        ? [
            // Default ticker data when watchlist is empty
            {
              'symbol': 'USD/TRY',
              'price': 34.2156,
              'change': 0.0234,
              'changePercent': 0.068
            },
            {
              'symbol': 'EUR/TRY',
              'price': 37.1234,
              'change': -0.0456,
              'changePercent': -0.123
            },
            {
              'symbol': 'GBP/TRY',
              'price': 43.5678,
              'change': 0.1234,
              'changePercent': 0.284
            },
            {
              'symbol': 'GOLD',
              'price': 2847.50,
              'change': -12.50,
              'changePercent': -0.437
            },
          ]
        : watchlistItems.map((item) => {
            'symbol': item['code'],
            'price': item['buyPrice'],
            'change': item['change'],
            'changePercent': item['changePercent']
          }).toList();

    return Container(
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

          return GestureDetector(
            onTap: () {
              // Navigate to asset detail screen
              Navigator.pushNamed(
                context,
                '/asset-detail-screen',
                arguments: {
                  'code': data['symbol'] as String,
                },
              );
            },
            child: Container(
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.3.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Birim',
              textAlign: TextAlign.left,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondaryLight,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Alış',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondaryLight,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 6.5.w),
              child: Text(
                'Satış',
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSarrafiyeList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _iscilikData.length,
      itemBuilder: (context, index) {
        final item = _iscilikData[index];
        final isLastItem = index == _iscilikData.length - 1;

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
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            child: Row(
              children: [
                // Name
                Expanded(
                  flex: 3,
                  child: Text(
                    item['name'] as String,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Buy price
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.formatNumber(item['buyPrice'] as double, decimalPlaces: 4),
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                // Sell price
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.formatNumber(item['sellPrice'] as double, decimalPlaces: 4),
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/sarrafiye-iscilik-screen');
  }}