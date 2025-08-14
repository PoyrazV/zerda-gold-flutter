import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
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
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  
  // Pagination variables
  List<Map<String, dynamic>> _allCurrencyData = [];
  int _displayedItemCount = 20;
  bool _isLoadingMore = false;
  
  // Search variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCurrencyData = [];

  // Use centralized mock data
  List<Map<String, dynamic>> get _featuredCurrencies => MockData.currencies;

  // Currency data from API - initialized with default values
  List<Map<String, dynamic>> get _currencyData => 
      _isSearching && _searchController.text.isNotEmpty 
          ? _filteredCurrencyData 
          : _allCurrencyData.take(_displayedItemCount).toList();
  
  List<Map<String, dynamic>> _defaultCurrencyData = [
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
    // Fetch initial currency data from API
    _fetchCurrencyData();
  }

  void _updateTicker() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchCurrencyData() async {
    try {
      print('Fetching currency data from API...');
      final data = await _currencyApiService.getFormattedCurrencyData();
      print('Received ${data.length} currencies from API');
      if (mounted && data.isNotEmpty) {
        setState(() {
          // Store all currencies
          _allCurrencyData = data;
          _displayedItemCount = 20; // Reset to initial count
          print('Showing ${_currencyData.length} currencies in dashboard');
        });
      }
    } catch (e) {
      print('Error fetching currency data: $e');
      // Use default data if API fails
      setState(() {
        _allCurrencyData = _defaultCurrencyData;
      });
    }
  }
  
  void _loadMoreCurrencies() {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _displayedItemCount = (_displayedItemCount + 20).clamp(0, _allCurrencyData.length);
          _isLoadingMore = false;
        });
      }
    });
  }
  
  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencyData = [];
      } else {
        _filteredCurrencyData = _allCurrencyData.where((currency) {
          final code = (currency['code'] as String).toLowerCase();
          final name = (currency['name'] as String).toLowerCase();
          final searchQuery = query.toLowerCase();
          return code.contains(searchQuery) || name.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
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

    // Fetch fresh data from API
    await _fetchCurrencyData();

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Döviz kurları güncellendi'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding and search icon
          AppHeader(
            textTopPadding: 1.0.h, 
            titleVerticalOffset: 12.0, 
            menuButtonVerticalOffset: 12.0,
            actions: [
              Transform.translate(
                offset: Offset(0, 12.0), // Same offset as menu button (menuButtonVerticalOffset)
                child: Padding(
                  padding: EdgeInsets.only(top: 1.0.h), // Same textTopPadding as menu button
                  child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _filterCurrencies('');
                      }
                    });
                  },
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                  padding: EdgeInsets.all(2.w),
                  ),
                ),
              ),
            ],
          ),

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
                    
                    // Search bar (shown when searching)
                    if (_isSearching)
                      Container(
                        height: 7.h,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Döviz ara (USD, Euro, Dolar...)',
                            hintStyle: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 14.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                            filled: true,
                            fillColor: AppTheme.lightTheme.colorScheme.surface,
                            contentPadding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                          onChanged: _filterCurrencies,
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
    final hasMoreToLoad = !_isSearching && _displayedItemCount < _allCurrencyData.length;
    
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.lightTheme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 0.5.h, bottom: 2.h),
        itemCount: _currencyData.length + (hasMoreToLoad ? 1 : 0),
        itemBuilder: (context, index) {
          // Load More button
          if (index == _currencyData.length && hasMoreToLoad) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: ElevatedButton(
                onPressed: _isLoadingMore ? null : _loadMoreCurrencies,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoadingMore
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Daha Fazla Göster',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            );
          }
          
          final currency = _currencyData[index];
          final isLastItem = index == _currencyData.length - 1 && !hasMoreToLoad;

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
