import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/gold_products_service.dart';
import '../../services/gold_websocket_service.dart';
import '../../services/theme_config_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/ticker_section.dart';

class GoldCoinPricesScreen extends StatefulWidget {
  const GoldCoinPricesScreen({Key? key}) : super(key: key);

  @override
  State<GoldCoinPricesScreen> createState() => _GoldCoinPricesScreenState();
}

class _GoldCoinPricesScreenState extends State<GoldCoinPricesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _refreshController;
  bool _isRefreshing = false;
  Map<String, dynamic>? _goldData;
  bool _isLoading = true;
  Timer? _periodicRefreshTimer;
  StreamSubscription? _goldUpdatesSubscription;
  final ThemeConfigService _themeConfigService = ThemeConfigService();

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

  // Gold data will be fetched from API
  List<Map<String, dynamic>> _goldCoinData = [
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
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
    
    // Listen to theme changes
    ThemeConfigService().addListener(_onThemeChanged);
    
    // Connect to WebSocket for real-time updates
    GoldWebSocketService.instance.connect();
    
    // Listen to WebSocket updates
    _goldUpdatesSubscription = GoldWebSocketService.instance.goldUpdates.listen((update) {
      print('🔄 Real-time gold update received: ${update['action']}');
      // Refresh data when products are added/updated/deleted
      if (mounted) {
        setState(() {
          // Clear any loading state
          _isLoading = false;
        });
        _fetchGoldPrice();
      }
    });
    
    // Load data immediately (will use persistent cache if available)
    _fetchGoldPrice();
    
    // Add small delay for network initialization, then refresh with fresh data
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        // Clear cache to force fresh API call
        GoldProductsService.clearCache();
        // Fetch fresh data from API
        _fetchGoldPrice();
        
        // Start periodic refresh timer
        _startPeriodicRefresh();
      }
    });
  }
  
  Future<void> _fetchGoldPrice() async {
    try {
      // Fetch products from admin panel
      final products = await GoldProductsService.getProductsWithPrices();
      
      // Use products from admin panel (no longer calling MetalsApiService)
      if (products.isNotEmpty) {
        if (mounted) {
          setState(() {
            _goldCoinData = products;
            _isLoading = false;
          });
        }
      } else {
        // No products available, show empty state
        if (mounted) {
          setState(() {
            _goldCoinData = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching gold data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateTicker() {
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
  
  // Start periodic refresh timer
  void _startPeriodicRefresh() {
    // Cancel existing timer if any
    _periodicRefreshTimer?.cancel();
    
    // Create new timer that refreshes every 30 seconds (reduced from 3 seconds)
    // WebSocket provides real-time updates, so periodic refresh is just backup
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Only refresh if the widget is still mounted
      if (mounted) {
        _silentRefresh();
      }
    });
  }
  
  // Silent refresh without loading indicators
  Future<void> _silentRefresh() async {
    try {
      // Fetch products from admin panel
      final products = await GoldProductsService.getProductsWithPrices();
      
      if (products.isNotEmpty) {
        if (mounted) {
          setState(() {
            _goldCoinData = products;
          });
        }
      } else {
        // No products available, show empty state
        if (mounted) {
          setState(() {
            _goldCoinData = [];
          });
        }
      }
    } catch (e) {
      // Silent fail - don't show error to user during background refresh
      print('Silent refresh error: $e');
    }
  }

  @override
  void dispose() {
    _periodicRefreshTimer?.cancel();
    _goldUpdatesSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    WatchlistService.removeListener(_updateTicker);
    ThemeConfigService().removeListener(_onThemeChanged);
    _refreshController.dispose();
    GoldWebSocketService.instance.disconnect();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Clear cache and refresh data when app comes to foreground
      GoldProductsService.clearCache();
      _fetchGoldPrice();
      // Restart periodic refresh when app resumes
      _startPeriodicRefresh();
    } else if (state == AppLifecycleState.paused) {
      // Stop periodic refresh when app goes to background to save resources
      _periodicRefreshTimer?.cancel();
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    _refreshController.forward();

    // Clear cache before fetching new data
    GoldProductsService.clearCache();
    
    // Fetch new data from API
    await _fetchGoldPrice();

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();
  }

  void _openMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menü açıldı'),
        backgroundColor: AppColors.primary,
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
          // DashboardHeader with custom padding for Gold screen
          DashboardHeader(customTopPadding: 3.1.h), // 3.h padding for lower logo position
          
          // Price ticker with API data
          const TickerSection(reduceBottomPadding: false),

          // Main content with table
          Expanded(
            child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.scaffoldBackgroundColor,
                ),
                child: Column(
                  children: [
                    // Table header - Dashboard style
                    Container(
                      width: double.infinity,
                      height: 4.h,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: AppColors.headerBackground, // Dynamic color
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'PRODUKT',
                              style: GoogleFonts.inter(
                                fontSize: 4.w,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfigService().secondaryColor, // Use secondary color from theme
                                height: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ANKAUF',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 4.w,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfigService().secondaryColor, // Use secondary color from theme
                                height: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'VERKAUF',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontSize: 4.w,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfigService().secondaryColor, // Use secondary color from theme
                                height: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Gold table - Dashboard style
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        color: AppColors.gold,
                        backgroundColor: AppColors.white,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _buildGoldList(),
                        ),
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
        color: AppColors.headerBackground,
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

  Widget _buildGoldList() {
    if (_isLoading) {
      return Container(
        height: 20.h,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.gold,
          ),
        ),
      );
    }
    
    if (_goldCoinData.isEmpty) {
      return Container(
        height: 20.h,
        child: Center(
          child: Text(
            'Veri yüklenemedi',
            style: GoogleFonts.inter(
              fontSize: 4.w,
              color: AppColors.disabled,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: _goldCoinData.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> gold = entry.value;
        return _buildGoldRow(gold, index);
      }).toList(),
    );
  }

  Widget _buildGoldRow(Map<String, dynamic> gold, int index) {
    final bool isPositive = gold['isPositive'] as bool;
    final double change = gold['change'] as double;
    final String currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    
    // Alternating row colors from theme config
    final Color backgroundColor = index.isEven 
        ? _themeConfigService.listRowEven
        : _themeConfigService.listRowOdd;
    
    return InkWell(
      onTap: () {
        // Navigate to asset detail screen
        Navigator.pushNamed(
          context,
          '/asset-detail-screen',
          arguments: {
            'code': gold['code'] as String,
            'name': gold['name'] as String?,
            'buyPrice': gold['buyPrice'],
            'sellPrice': gold['sellPrice'],
            'change': gold['change'],
            'isPositive': gold['isPositive'],
          },
        );
      },
      child: Container(
      height: 8.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.w),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left section - Gold name and time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 0.5.w),
                Padding(
                  padding: EdgeInsets.only(top: 1.w),
                  child: Text(
                    gold['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 4.w,
                      fontWeight: FontWeight.bold, // Bold weight for name
                      color: AppColors.text,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 2.w),
                Padding(
                  padding: EdgeInsets.only(top: 2.w),
                  child: Text(
                    currentTime,
                    style: GoogleFonts.inter(
                      fontSize: 3.w,
                      fontWeight: FontWeight.normal,
                      color: AppColors.disabled,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Middle section - Buy price
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(top: 1.w),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  CurrencyFormatter.formatNumber(gold['buyPrice'] as double, decimalPlaces: 2),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 4.w,
                    fontWeight: FontWeight.w600, // Semi-bold weight
                    color: _themeConfigService.listNameText,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),
          // Right section - Sell price and percentage change
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 0.5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 1.w),
                    child: Text(
                      CurrencyFormatter.formatNumber(gold['sellPrice'] as double, decimalPlaces: 2),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 4.w,
                        fontWeight: FontWeight.w600, // Semi-bold weight
                        color: AppColors.text,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.5.w),
                  Padding(
                    padding: EdgeInsets.only(top: 1.5.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.w),
                      decoration: BoxDecoration(
                        color: isPositive 
                            ? _themeConfigService.listPrimaryColor
                            : _themeConfigService.listSecondaryColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isPositive 
                              ? _themeConfigService.listPrimaryBorder.withOpacity(0.2)
                              : _themeConfigService.listSecondaryBorder.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '%${change.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                        style: GoogleFonts.inter(
                          fontSize: 2.7.w,
                          fontWeight: FontWeight.w500, // Medium weight
                          color: isPositive 
                              ? _themeConfigService.listPrimaryText
                              : _themeConfigService.listSecondaryText,
                          height: 1.0,
                        ),
                      ),
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
                            CurrencyFormatter.formatNumber(data['price'] as double, decimalPlaces: 4),
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
