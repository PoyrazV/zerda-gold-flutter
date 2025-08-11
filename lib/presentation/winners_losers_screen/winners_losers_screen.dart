import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import './widgets/segmented_control_widget.dart';
import './widgets/timeframe_filter_widget.dart';
import './widgets/financial_instruments_list_widget.dart';

class WinnersLosersScreen extends StatefulWidget {
  const WinnersLosersScreen({Key? key}) : super(key: key);

  @override
  State<WinnersLosersScreen> createState() => _WinnersLosersScreenState();
}

class _WinnersLosersScreenState extends State<WinnersLosersScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;
  int _selectedTab =
      1; // 0: KAZANANLAR, 1: KAYBEDENLER (Losers selected by default)
  int _selectedTimeframe = 1; // 0: GÜN, 1: HAFTA (Week selected by default)

  // Mock data for winners
  final List<Map<String, dynamic>> _winnersData = [
    {
      "name": "ALTIN/USD",
      "absoluteChange": "+12.50",
      "percentageChange": 8.45,
      "isPositive": true,
    },
    {
      "name": "GÜMÜŞ/USD",
      "absoluteChange": "+2.30",
      "percentageChange": 6.21,
      "isPositive": true,
    },
    {
      "name": "BAKIR/USD",
      "absoluteChange": "+0.85",
      "percentageChange": 4.15,
      "isPositive": true,
    },
    {
      "name": "EUR/USD",
      "absoluteChange": "+0.012",
      "percentageChange": 3.76,
      "isPositive": true,
    },
    {
      "name": "GBP/USD",
      "absoluteChange": "+0.021",
      "percentageChange": 2.89,
      "isPositive": true,
    },
  ];

  // Mock data for losers
  final List<Map<String, dynamic>> _losersData = [
    {
      "name": "PLATIN/USD",
      "absoluteChange": "-3.100",
      "percentageChange": -7.68,
      "isPositive": false,
    },
    {
      "name": "GÜMÜŞ ONS",
      "absoluteChange": "-97,00",
      "percentageChange": -5.23,
      "isPositive": false,
    },
    {
      "name": "PETROL",
      "absoluteChange": "-2.45",
      "percentageChange": -4.12,
      "isPositive": false,
    },
    {
      "name": "GAZ NATURAL",
      "absoluteChange": "-0.89",
      "percentageChange": -3.67,
      "isPositive": false,
    },
    {
      "name": "USD/TRY",
      "absoluteChange": "-0.156",
      "percentageChange": -2.94,
      "isPositive": false,
    },
  ];

  final List<String> _timeframes = [
    "GÜN",
    "HAFTA",
    "AY",
    "6 AY",
    "YIL",
    "5 YIL",
    "MAX"
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

    // Mock data update (simulate real-time changes)
    setState(() {
      for (var item in _winnersData) {
        final change = (DateTime.now().millisecond % 50) * 0.01;
        item['percentageChange'] =
            (item['percentageChange'] as double) + change;
      }

      for (var item in _losersData) {
        final change = (DateTime.now().millisecond % 50) * 0.01;
        item['percentageChange'] =
            (item['percentageChange'] as double) - change;
      }
    });

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Veriler güncellendi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
    HapticFeedback.selectionClick();
  }

  void _onTimeframeChanged(int index) {
    setState(() {
      _selectedTimeframe = index;
    });
    HapticFeedback.selectionClick();
    _handleRefresh(); // Refresh data when timeframe changes
  }

  void _onBottomNavTap(int index) {
    final List<String> routes = [
      AppRoutes.currencyExchange, // Döviz
      AppRoutes.dashboard, // Altın (using dashboard as placeholder)
      AppRoutes.currencyConverter, // Çevirici
      AppRoutes.priceAlerts, // Alarm
      AppRoutes.portfolioManagement, // Portföy
    ];

    if (index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _selectedTab == 0 ? _winnersData : _losersData;

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

            // Segmented control for Winners/Losers
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: SegmentedControlWidget(
                selectedIndex: _selectedTab,
                onChanged: _onTabChanged,
              ),
            ),

            // Timeframe filter
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: TimeframeFilterWidget(
                timeframes: _timeframes,
                selectedIndex: _selectedTimeframe,
                onChanged: _onTimeframeChanged,
              ),
            ),

            SizedBox(height: 2.h),

            // Financial instruments list
            Expanded(
              child: FinancialInstrumentsListWidget(
                data: currentData,
                isWinners: _selectedTab == 0,
                onRefresh: _handleRefresh,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/winners-losers-screen');
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
                    print('Winners Losers hamburger button tapped!');
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
      height: 9.h,
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
    );
  }}
