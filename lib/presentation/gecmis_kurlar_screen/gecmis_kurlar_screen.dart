import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ticker_section.dart';

class GecmisKurlarScreen extends StatefulWidget {
  const GecmisKurlarScreen({Key? key}) : super(key: key);

  @override
  State<GecmisKurlarScreen> createState() => _GecmisKurlarScreenState();
}

class _GecmisKurlarScreenState extends State<GecmisKurlarScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;
  String _selectedType = 'DOVIZ'; // DOVIZ or ALTIN
  String _selectedDate = '31.07.2025';
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  List<Map<String, dynamic>> _allCurrencyData = [];
  bool _isLoading = true;

  // Geçmiş döviz kurları (EUR bazlı)
  final Map<String, List<Map<String, dynamic>>> _historicalData = {
    'DOVIZ': [
      {
        'code': 'USD/EUR',
        'name': 'Amerikan Doları',
        'buyPrice': 0.8789,
        'sellPrice': 0.8772,
      },
      {
        'code': 'TRY/EUR',
        'name': 'Türk Lirası',
        'buyPrice': 0.0217,
        'sellPrice': 0.0216,
      },
      {
        'code': 'GBP/EUR',
        'name': 'İngiliz Sterlini',
        'buyPrice': 1.1551,
        'sellPrice': 1.1596,
      },
      {
        'code': 'CHF/EUR',
        'name': 'İsviçre Frangı',
        'buyPrice': 1.0671,
        'sellPrice': 1.0746,
      },
      {
        'code': 'AUD/EUR',
        'name': 'Avustralya Doları',
        'buyPrice': 0.5477,
        'sellPrice': 0.5628,
      },
      {
        'code': 'CAD/EUR',
        'name': 'Kanada Doları',
        'buyPrice': 0.6238,
        'sellPrice': 0.6397,
      },
      {
        'code': 'SAR/EUR',
        'name': 'Suudi Riyali',
        'buyPrice': 0.2309,
        'sellPrice': 0.2371,
      },
      {
        'code': 'JPY/EUR',
        'name': 'Japon Yeni',
        'buyPrice': 0.0058,
        'sellPrice': 0.0059,
      },
    ],
    'ALTIN': [
      {
        'code': 'GRAM',
        'name': 'Gram Altın',
        'buyPrice': 61.78,
        'sellPrice': 61.82,
      },
      {
        'code': 'YÇEYREK',
        'name': 'Yeni Çeyrek Altın',
        'buyPrice': 62.73,
        'sellPrice': 62.77,
      },
      {
        'code': 'EÇEYREK',
        'name': 'Eski Çeyrek Altın',
        'buyPrice': 62.05,
        'sellPrice': 62.09,
      },
      {
        'code': 'YYARIM',
        'name': 'Yeni Yarım Altın',
        'buyPrice': 125.47,
        'sellPrice': 125.54,
      },
      {
        'code': 'EYARIM',
        'name': 'Eski Yarım Altın',
        'buyPrice': 124.11,
        'sellPrice': 124.18,
      },
      {
        'code': 'YTAM',
        'name': 'Yeni Tam Altın',
        'buyPrice': 250.93,
        'sellPrice': 251.08,
      },
      {
        'code': 'ETAM',
        'name': 'Eski Tam Altın',
        'buyPrice': 248.22,
        'sellPrice': 248.37,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
    // Load currency data from API
    _loadCurrencyData();
  }
  
  Future<void> _loadCurrencyData() async {
    try {
      final currencies = await _currencyApiService.getFormattedCurrencyData();
      if (mounted) {
        setState(() {
          _allCurrencyData = currencies;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading currency data: $e');
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

    // Reload data from API
    await _loadCurrencyData();

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Geçmiş kurlar güncellendi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectDate() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme,
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _selectedDate = '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18214F),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding
          _buildHeader(),

          // Price ticker with API data
          const TickerSection(reduceBottomPadding: false),

          // Main content with fixed controls and header
          Expanded(
            child: Column(
              children: [
                SizedBox(height: 2.h),
                
                // Type selector and date picker - FIXED
                _buildControls(),

                SizedBox(height: 1.h),

                // Table header - FIXED
                _buildTableHeader(),

                // Historical rates list - SCROLLABLE
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildHistoricalRatesList(),
                          SizedBox(height: 2.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
        color: const Color(0xFF18214F),
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
                'Geçmiş Kurlar',
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

  Widget _buildControls() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      height: 5.5.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date picker at the start
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(0xFF18214F),
                      size: 15.sp,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      _selectedDate,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 3.h,
            color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          
          // DÖVİZ button in the middle
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'DOVIZ';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedType == 'DOVIZ' 
                      ? Colors.white
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    'DÖVİZ',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: _selectedType == 'DOVIZ' 
                          ? const Color(0xFF18214F)
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontWeight: _selectedType == 'DOVIZ' 
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 3.h,
            color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          
          // ALTIN button
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'ALTIN';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedType == 'ALTIN' 
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Center(
                  child: Text(
                    'ALTIN',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: _selectedType == 'ALTIN' 
                          ? const Color(0xFF18214F)
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontWeight: _selectedType == 'ALTIN' 
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 4.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: const BoxDecoration(
        color: Color(0xFF18214F),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'PRODUKT',
              style: GoogleFonts.inter(
                fontSize: 4.w,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE8D095),
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
                color: const Color(0xFFE8D095),
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
                color: const Color(0xFFE8D095),
                height: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalRatesList() {
    if (_isLoading) {
      return Container(
        height: 20.h,
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFFFD700),
          ),
        ),
      );
    }
    
    // Filter data based on selected type - show all currencies for DOVIZ, gold data for ALTIN
    List<Map<String, dynamic>> data;
    final displayPrice = 4; // Always show 4 decimal places for currencies
    
    if (_selectedType == 'DOVIZ') {
      // Show all currencies from API
      data = _allCurrencyData;
    } else {
      // Show gold data from historical data
      data = _historicalData[_selectedType] ?? [];
    }
    
    return Column(
      children: data.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> item = entry.value;
        final currentDisplayPrice = _selectedType == 'DOVIZ' ? 4 : 2;
        
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Darker gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows
        
        return Container(
          height: 8.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.w),
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left section - Currency code or name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedType == 'DOVIZ' 
                          ? (item['name'] as String)
                          : (item['code'] as String),
                      style: GoogleFonts.inter(
                        fontSize: 4.w,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2939),
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Middle section - Buy price
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(top: 5.w),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      _selectedType == 'DOVIZ' 
                          ? CurrencyFormatter.formatSmartPrice(item['buyPrice'] as double)
                          : CurrencyFormatter.formatNumber(item['buyPrice'] as double, decimalPlaces: currentDisplayPrice),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 4.w,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2939),
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
              // Right section - Sell price
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(right: 3.w, top: 5.w),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      _selectedType == 'DOVIZ' 
                          ? CurrencyFormatter.formatSmartPrice(
                              item['sellPrice'] as double? ?? (item['buyPrice'] as double) * 1.002
                            )
                          : CurrencyFormatter.formatNumber(
                              item['sellPrice'] as double, 
                              decimalPlaces: currentDisplayPrice
                            ),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 4.w,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2939),
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/gecmis-kurlar-screen');
  }}