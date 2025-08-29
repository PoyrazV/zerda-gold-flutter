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
import '../../widgets/dashboard_header.dart';
import '../../theme/app_colors.dart';

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
  final ThemeConfigService _themeConfigService = ThemeConfigService();
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
    // Listen to theme changes
    ThemeConfigService().addListener(_onThemeChanged);
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

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild with new theme colors
      });
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    WatchlistService.removeListener(_updateTicker);
    ThemeConfigService().removeListener(_onThemeChanged);
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
        backgroundColor: AppColors.primary,
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
      backgroundColor: AppColors.primary,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding
          const DashboardHeader(),

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
                    color: AppColors.primary,
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
                      color: AppColors.primary,
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
                          ? AppColors.primary
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
                          ? AppColors.primary
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
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
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
    );
  }

  Widget _buildHistoricalRatesList() {
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
        
        // Alternating row colors from theme
        final Color backgroundColor = index.isEven 
            ? _themeConfigService.listRowEven
            : _themeConfigService.listRowOdd;
        
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
                        color: AppColors.text,
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
                        color: AppColors.text,
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
                        color: AppColors.text,
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