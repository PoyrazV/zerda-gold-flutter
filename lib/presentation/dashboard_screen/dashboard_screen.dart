import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/price_ticker.dart';
import '../../core/mock_data.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Use centralized mock data
  List<Map<String, dynamic>> get _featuredCurrencies => MockData.currencies;

  // Mock currency data
  final List<Map<String, dynamic>> _currencyData = [
    {
      "code": "USDTRY",
      "name": "Amerikan Doları",
      "buyPrice": 34.5842,
      "sellPrice": 34.5958,
      "change": -0.03,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "EURTRY",
      "name": "Euro",
      "buyPrice": 37.4763,
      "sellPrice": 37.4891,
      "change": 0.42,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "GBPTRY",
      "name": "İngiliz Sterlini",
      "buyPrice": 43.7924,
      "sellPrice": 43.8056,
      "change": 0.26,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "CHFTRY",
      "name": "İsviçre Frangı",
      "buyPrice": 39.2134,
      "sellPrice": 39.2267,
      "change": -0.15,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "AUDTRY",
      "name": "Avustralya Doları",
      "buyPrice": 22.8934,
      "sellPrice": 22.9012,
      "change": 0.08,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "CADTRY",
      "name": "Kanada Doları",
      "buyPrice": 25.9421,
      "sellPrice": 25.9501,
      "change": -0.21,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "JPYTRY",
      "name": "Japon Yeni",
      "buyPrice": 0.2321,
      "sellPrice": 0.2324,
      "change": 0.41,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "SEKTRY",
      "name": "İsveç Kronu",
      "buyPrice": 3.1234,
      "sellPrice": 3.1267,
      "change": 0.18,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "NOKTRY",
      "name": "Norveç Kronu",
      "buyPrice": 3.0845,
      "sellPrice": 3.0878,
      "change": -0.12,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "DKKTRY",
      "name": "Danimarka Kronu",
      "buyPrice": 5.0234,
      "sellPrice": 5.0267,
      "change": 0.35,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "RUBTRY",
      "name": "Rus Rublesi",
      "buyPrice": 0.3456,
      "sellPrice": 0.3478,
      "change": -0.45,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "CNYТRY",
      "name": "Çin Yuanı",
      "buyPrice": 4.7234,
      "sellPrice": 4.7267,
      "change": 0.15,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "KRWTRY",
      "name": "Güney Kore Wonu",
      "buyPrice": 0.0251,
      "sellPrice": 0.0254,
      "change": -0.08,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "SGDTRY",
      "name": "Singapur Doları",
      "buyPrice": 25.4567,
      "sellPrice": 25.4789,
      "change": 0.22,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "AEDTRY",
      "name": "BAE Dirhemi",
      "buyPrice": 9.4123,
      "sellPrice": 9.4156,
      "change": -0.02,
      "isPositive": false,
      "timestamp": "10:12",
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
    await Future.delayed(const Duration(seconds: 1));

    // Mock data update
    setState(() {
      for (var currency in _currencyData) {
        currency['buyPrice'] = (currency['buyPrice'] as double) +
            (DateTime.now().millisecond % 10 - 5) * 0.001;
        currency['sellPrice'] = (currency['sellPrice'] as double) +
            (DateTime.now().millisecond % 10 - 5) * 0.001;
        currency['change'] = (DateTime.now().millisecond % 200 - 100) * 0.01;
        currency['isPositive'] = currency['change'] > 0;
      }

      // Featured currencies now use centralized data - no separate update needed
    });

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Döviz kurları güncellendi'),
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
          const PriceTicker(),

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

                    // Currency table
                    Expanded(
                      child: _buildCurrencyTable(),
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


  Widget _buildCurrencyTable() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 0.5.h),
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
          child: _buildCurrencyRow(currency),
        );
      },
      ),
    );
  }

  Widget _buildCurrencyRow(Map<String, dynamic> currency) {
    final bool isPositive = currency['isPositive'] as bool;

    return InkWell(
      onTap: () {
        // Navigate to asset detail screen with currency data
        Navigator.pushNamed(
          context, 
          '/asset-detail-screen',
          arguments: {
            'code': currency['code'],
          },
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 1.2.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Currency info - with timestamp
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currency['code'] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.1.h),
                  Text(
                    currency['name'] as String,
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
                    currency['timestamp'] as String,
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
                  '₺${CurrencyFormatter.formatExchangeRate(currency['buyPrice'] as double)}',
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
                      '₺${CurrencyFormatter.formatExchangeRate(currency['sellPrice'] as double)}',
                      style: AppTheme.dataTextStyle(
                        isLight: true,
                        fontSize: 12.sp,
                      ).copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 0.2.h),
                    Text(
                      CurrencyFormatter.formatPercentageChange(currency['change'] as double),
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
    return CustomBottomNavigationBar(currentRoute: '/dashboard-screen');
  }


  // Removed _formatPrice method - now using CurrencyFormatter.formatExchangeRate


}
