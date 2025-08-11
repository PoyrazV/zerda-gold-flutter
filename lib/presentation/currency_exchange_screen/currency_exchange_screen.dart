import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bottom_navigation_widget.dart';
import './widgets/currency_table_widget.dart';
import './widgets/header_widget.dart';

class CurrencyExchangeScreen extends StatefulWidget {
  const CurrencyExchangeScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyExchangeScreen> createState() => _CurrencyExchangeScreenState();
}

class _CurrencyExchangeScreenState extends State<CurrencyExchangeScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Featured currencies for the featured cards section
  final List<Map<String, dynamic>> _featuredCurrencies = [
    {
      "code": "USD/TRY",
      "sellPrice": 34.5958,
      "change": -0.03,
      "isPositive": false,
    },
    {
      "code": "EUR/TRY",
      "sellPrice": 37.4891,
      "change": 0.42,
      "isPositive": true,
    },
    {
      "code": "JPY/TRY",
      "sellPrice": 0.2324,
      "change": 0.41,
      "isPositive": true,
    },
    {
      "code": "GBP/TRY",
      "sellPrice": 43.8056,
      "change": 0.26,
      "isPositive": true,
    },
  ];

  // Mock currency data
  final List<Map<String, dynamic>> _currencyData = [
    {
      "code": "USDTRY",
      "name": "American Dollar",
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
      "code": "EURUSD",
      "name": "EUR/USD",
      "buyPrice": 1.0856,
      "sellPrice": 1.0862,
      "change": 0.12,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "GBPTRY",
      "name": "British Pound",
      "buyPrice": 43.7924,
      "sellPrice": 43.8056,
      "change": 0.26,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "CHFTRY",
      "name": "Swiss Franc",
      "buyPrice": 39.2134,
      "sellPrice": 39.2267,
      "change": -0.15,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "AUDTRY",
      "name": "Australian Dollar",
      "buyPrice": 22.8934,
      "sellPrice": 22.9012,
      "change": 0.08,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "CADTRY",
      "name": "Canadian Dollar",
      "buyPrice": 25.9421,
      "sellPrice": 25.9501,
      "change": -0.21,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "SARTRY",
      "name": "Saudi Riyal",
      "buyPrice": 9.2234,
      "sellPrice": 9.2267,
      "change": 0.05,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "JPYTRY",
      "name": "Japanese Yen",
      "buyPrice": 0.2321,
      "sellPrice": 0.2324,
      "change": 0.41,
      "isPositive": true,
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
  }

  @override
  void dispose() {
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

      for (var featured in _featuredCurrencies) {
        featured['sellPrice'] = (featured['sellPrice'] as double) +
            (DateTime.now().millisecond % 10 - 5) * 0.001;
        featured['change'] = (DateTime.now().millisecond % 200 - 100) * 0.01;
        featured['isPositive'] = featured['change'] > 0;
      }
    });

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exchange rates updated'),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark navy background
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF10B981), // Green accent for refresh indicator
        backgroundColor: const Color(0xFF1E293B),
        child: Column(
          children: [
            // Header with ZERDA branding
            HeaderWidget(
              onMenuTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Menu opened'),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Featured currencies cards section
            Container(
              height: 16.h,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _featuredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _featuredCurrencies[index];
                  final bool isPositive = currency['isPositive'] as bool;
                  final Color changeColor = isPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444);

                  return Container(
                    width: 35.w,
                    margin: EdgeInsets.only(right: 3.w),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currency['code'] as String,
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.formatExchangeRate(currency['sellPrice'] as double),
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              CurrencyFormatter.formatPercentageChange(currency['change'] as double),
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Main content with table
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Unit',
                              style: TextStyle(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Buy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Sell',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Currency table
                    Expanded(
                      child: CurrencyTableWidget(
                        currencyData: _currencyData,
                        onRefresh: _handleRefresh,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom navigation
            BottomNavigationWidget(
              currentIndex: 0, // Döviz is active
              onTap: (index) {
                final List<String> tabs = [
                  'Döviz',
                  'Altın',
                  'Çevirici',
                  'Alarm',
                  'Portföy'
                ];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to ${tabs[index]} tab'),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Removed _formatPrice method - now using CurrencyFormatter.formatExchangeRate
}
