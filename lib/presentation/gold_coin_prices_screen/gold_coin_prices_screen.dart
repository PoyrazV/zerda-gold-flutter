import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';

class GoldCoinPricesScreen extends StatefulWidget {
  const GoldCoinPricesScreen({Key? key}) : super(key: key);

  @override
  State<GoldCoinPricesScreen> createState() => _GoldCoinPricesScreenState();
}

class _GoldCoinPricesScreenState extends State<GoldCoinPricesScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Featured gold items for the featured cards section
  final List<Map<String, dynamic>> _featuredGoldData = [
    {
      "code": "GRAM ALTIN",
      "sellPrice": 2654.30,
      "change": 0.65,
      "isPositive": true,
    },
    {
      "code": "ÇEYREK ALTIN",
      "sellPrice": 2891.75,
      "change": 0.85,
      "isPositive": true,
    },
    {
      "code": "YARIM ALTIN",
      "sellPrice": 5783.50,
      "change": 1.12,
      "isPositive": true,
    },
    {
      "code": "TAM ALTIN",
      "sellPrice": 11567.00,
      "change": 0.95,
      "isPositive": true,
    },
    {
      "code": "ATA ALTIN",
      "sellPrice": 11485.75,
      "change": 1.25,
      "isPositive": true,
    },
    {
      "code": "GÜMÜŞ",
      "sellPrice": 34.25,
      "change": -0.45,
      "isPositive": false,
    },
  ];

  // Turkish gold coin prices data
  final List<Map<String, dynamic>> _goldCoinData = [
    {
      "code": "GRAM",
      "name": "Gram Altın",
      "buyPrice": 2640.50,
      "sellPrice": 2654.30,
      "change": 0.65,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "YÇEYREK",
      "name": "Yeni Çeyrek Altın",
      "buyPrice": 2876.50,
      "sellPrice": 2891.75,
      "change": 0.85,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "EÇEYREK",
      "name": "Eski Çeyrek Altın",
      "buyPrice": 2845.25,
      "sellPrice": 2860.40,
      "change": -0.45,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "YYARIM",
      "name": "Yeni Yarım Altın",
      "buyPrice": 5753.00,
      "sellPrice": 5783.50,
      "change": 1.12,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "EYARIM",
      "name": "Eski Yarım Altın",
      "buyPrice": 5690.75,
      "sellPrice": 5720.80,
      "change": -0.28,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "YTAM",
      "name": "Yeni Tam Altın",
      "buyPrice": 11506.00,
      "sellPrice": 11567.00,
      "change": 0.95,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "ETAM",
      "name": "Eski Tam Altın",
      "buyPrice": 11381.50,
      "sellPrice": 11441.60,
      "change": -0.62,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "YATA",
      "name": "Yeni Ata Altın",
      "buyPrice": 11425.25,
      "sellPrice": 11485.75,
      "change": 1.25,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "EATA",
      "name": "Eski Ata Altın",
      "buyPrice": 11302.80,
      "sellPrice": 11362.40,
      "change": -0.33,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "CUMHUR",
      "name": "Cumhuriyet Altını",
      "buyPrice": 11548.90,
      "sellPrice": 11610.30,
      "change": 0.78,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "22AYAR",
      "name": "22 Ayar Bilezik",
      "buyPrice": 2654.30,
      "sellPrice": 2668.75,
      "change": 0.65,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "18AYAR",
      "name": "18 Ayar Bilezik",
      "buyPrice": 2165.50,
      "sellPrice": 2178.25,
      "change": 0.42,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "14AYAR",
      "name": "14 Ayar Bilezik",
      "buyPrice": 1687.75,
      "sellPrice": 1698.50,
      "change": -0.15,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "GUMUS",
      "name": "Gümüş (Gram)",
      "buyPrice": 33.45,
      "sellPrice": 34.25,
      "change": -0.45,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "ONSALTIN",
      "name": "Ons Altın (USD)",
      "buyPrice": 2731.25,
      "sellPrice": 2746.85,
      "change": -0.25,
      "isPositive": false,
      "timestamp": "10:15",
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
    WatchlistService.removeListener(_updateTicker);
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

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data update with realistic gold price fluctuations
    setState(() {
      for (var coin in _goldCoinData) {
        final randomChange = (DateTime.now().millisecond % 40 - 20) * 0.25;
        coin['buyPrice'] = (coin['buyPrice'] as double) + randomChange;
        coin['sellPrice'] = (coin['sellPrice'] as double) + randomChange;
        coin['change'] = (DateTime.now().millisecond % 300 - 150) * 0.01;
        coin['isPositive'] = coin['change'] > 0;
      }

      for (var featured in _featuredGoldData) {
        final randomChange = (DateTime.now().millisecond % 40 - 20) * 0.25;
        featured['sellPrice'] = (featured['sellPrice'] as double) + randomChange;
        featured['change'] = (DateTime.now().millisecond % 300 - 150) * 0.01;
        featured['isPositive'] = featured['change'] > 0;
      }
    });

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Altın fiyatları güncellendi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menü açıldı'),
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
      body: Column(
        children: [
          // Header with ZERDA branding
          AppHeader(textTopPadding: 1.0.h),

          // Price ticker
          _buildPriceTicker(),

          // Main content with table
          Expanded(
            child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.scaffoldBackgroundColor,
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
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
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Birim',
                              textAlign: TextAlign.left,
                              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
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
                                color: Colors.white,
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
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Gold table
                    Expanded(
                      child: Container(
                        color: AppTheme.lightTheme.scaffoldBackgroundColor,
                        child: _buildGoldTable(),
                      ),
                    ),
                  ],
                ),
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
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

              // ZERDA title
              Text(
                'ZERDA',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space to center the title
              SizedBox(width: 48), // Same width as menu button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldTable() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 0.5.h),
        itemCount: _goldCoinData.length,
      itemBuilder: (context, index) {
        final gold = _goldCoinData[index];
        final isLastItem = index == _goldCoinData.length - 1;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.scaffoldBackgroundColor,
            border: isLastItem ? null : Border(
              bottom: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: _buildGoldRow(gold),
        );
      },
      ),
    );
  }

  Widget _buildGoldRow(Map<String, dynamic> gold) {
    final bool isPositive = gold['isPositive'] as bool;

    return InkWell(
      onTap: () {
        // Navigate to asset detail screen with gold data
        Navigator.pushNamed(
          context, 
          '/asset-detail-screen',
          arguments: {
            'code': gold['code'],
          },
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 1.2.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gold info - with timestamp
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gold['code'] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.1.h),
                  Text(
                    gold['name'] as String,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.1.h),
                  Text(
                    gold['timestamp'] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Buy price - better aligned
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  CurrencyFormatter.formatTRY(gold['buyPrice'] as double),
                  style: AppTheme.dataTextStyle(
                    isLight: true,
                    fontSize: 12.sp,
                  ).copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),

            // Sell price and percentage change - lowered position
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 2.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 2.0.h), // Push sell price down even more
                    Text(
                      CurrencyFormatter.formatTRY(gold['sellPrice'] as double),
                      style: AppTheme.dataTextStyle(
                        isLight: true,
                        fontSize: 12.sp,
                      ).copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 0.2.h),
                    Text(
                      CurrencyFormatter.formatPercentageChange(gold['change'] as double),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/gold-coin-prices-screen');
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
        ),
      ],
    );
  }

  // Removed _formatPrice method - now using CurrencyFormatter.formatTRY

  String _convertToGoldFormat(String displayCode) {
    // Convert display format (GRAM ALTIN) to code format (GRAM)
    switch (displayCode) {
      case 'GRAM ALTIN':
        return 'GRAM';
      case 'ÇEYREK ALTIN':
        return 'YÇEYREK';
      case 'YARIM ALTIN':
        return 'YYARIM';
      case 'TAM ALTIN':
        return 'YTAM';
      case 'ATA ALTIN':
        return 'YATA';
      case 'GÜMÜŞ':
        return 'GUMUS';
      default:
        // If already in code format, return as is
        return displayCode;
    }
  }}
