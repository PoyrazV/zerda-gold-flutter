import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
import '../../services/gold_products_service.dart';
import '../../services/theme_config_service.dart';
import '../../widgets/ticker_section.dart';
import '../../widgets/dashboard_header.dart';
import './widgets/interactive_chart_widget.dart';
import './widgets/key_metrics_widget.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({Key? key}) : super(key: key);

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  Map<String, dynamic>? assetData;
  bool _isLoading = true;


  String _getCurrencyNameForSymbol(String symbol) {
    // If the symbol already contains /EUR, return as is
    if (symbol.contains('/EUR')) {
      return symbol;
    }
    
    switch (symbol) {
      case 'USDTRY':
      case 'USD':
        return 'USD/EUR';
      case 'EURTRY':
      case 'EUR':
        return 'EUR';
      case 'GBPTRY':
      case 'GBP':
        return 'GBP/EUR';
      case 'CHFTRY':
      case 'CHF':
        return 'CHF/EUR';
      case 'AUDTRY':
      case 'AUD':
        return 'AUD/EUR';
      case 'CADTRY':
      case 'CAD':
        return 'CAD/EUR';
      case 'JPYTRY':
      case 'JPY':
        return 'JPY/EUR';
      case 'SEKTRY':
      case 'SEK':
        return 'SEK/EUR';
      case 'NOKTRY':
      case 'NOK':
        return 'NOK/EUR';
      case 'DKKTRY':
      case 'DKK':
        return 'DKK/EUR';
      case 'RUBTRY':
      case 'RUB':
        return 'RUB/EUR';
      case 'CNYTRY':
      case 'CNY':
        return 'CNY/EUR';
      case 'KRWTRY':
      case 'KRW':
        return 'KRW/EUR';
      case 'SGDTRY':
      case 'SGD':
        return 'SGD/EUR';
      case 'AEDTRY':
      case 'AED':
        return 'AED/EUR';
      // Additional currencies
      case 'PLN':
        return 'PLN/EUR';
      case 'HRK':
        return 'HRK/EUR';
      case 'CZK':
        return 'CZK/EUR';
      case 'HUF':
        return 'HUF/EUR';
      case 'BGN':
        return 'BGN/EUR';
      case 'RON':
        return 'RON/EUR';
      case 'ISK':
        return 'ISK/EUR';
      case 'THB':
        return 'THB/EUR';
      case 'MYR':
        return 'MYR/EUR';
      case 'ZAR':
        return 'ZAR/EUR';
      case 'INR':
        return 'INR/EUR';
      case 'IDR':
        return 'IDR/EUR';
      case 'PHP':
        return 'PHP/EUR';
      case 'MXN':
        return 'MXN/EUR';
      case 'BRL':
        return 'BRL/EUR';
      // Gold types (both full codes and 3-letter codes)
      case 'GRAM':
      case 'GRM':
        return 'Gram Altın';
      case 'YÇEYREK':
      case 'CYR':
        return 'Çeyrek Altın';
      case 'EÇEYREK':
        return 'Eski Çeyrek Altın';
      case 'YYARIM':
      case 'YRM':
        return 'Yarım Altın';
      case 'EYARIM':
        return 'Eski Yarım Altın';
      case 'YTAM':
      case 'TAM':
        return 'Tam Altın';
      case 'ETAM':
        return 'Eski Tam Altın';
      case 'YATA':
      case 'ATA':
        return 'Ata Altın';
      case 'EATA':
        return 'Eski Ata Altın';
      case 'CUMHUR':
      case 'CMH':
        return 'Cumhuriyet Altını';
      case '22AYAR':
        return '22 Ayar Bilezik';
      case '18AYAR':
        return '18 Ayar Bilezik';
      case '14AYAR':
        return '14 Ayar Bilezik';
      case 'GUMUS':
      case 'GMS':
        return 'Gümüş (Gram)';
      case 'ONSALTIN':
      case 'ONS':
        return 'Ons Altın';
      case 'GRS':
        return 'Gremse Altın';
      case 'BSL':
        return 'Beşli Altın';
      case 'RST':
        return 'Reşat Altın';
      case 'HMT':
        return 'Hamit Altın';
      default:
        // For any unknown currency, show it with EUR
        return '$symbol/EUR';
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize with default data, will be overridden in didChangeDependencies
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments from route
    final Map<String, dynamic>? arguments = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    String symbol = 'USD';
    if (arguments != null && arguments['code'] != null) {
      symbol = arguments['code'] as String;
      print('AssetDetailScreen: Received currency code: $symbol');
      
      // If we have direct price data from gold screen, use it
      if (arguments['buyPrice'] != null && arguments['sellPrice'] != null) {
        setState(() {
          assetData = {
            "symbol": symbol,
            "name": arguments['name'] ?? _getCurrencyNameForSymbol(symbol),
            "currentPrice": CurrencyFormatter.formatNumber(arguments['sellPrice'] ?? 0.0, decimalPlaces: 2),
            "buyPrice": arguments['buyPrice'] ?? 0.0,
            "sellPrice": arguments['sellPrice'] ?? 0.0,
            "priceChange": CurrencyFormatter.formatPercentageChange(arguments['change'] ?? 0.0).replaceAll('%', ''),
            "changePercent": CurrencyFormatter.formatPercentageChange(arguments['change'] ?? 0.0),
            "isPositive": arguments['isPositive'] ?? false,
            "openingPrice": CurrencyFormatter.formatNumber((arguments['sellPrice'] ?? 0.0) * 0.998, decimalPlaces: 2),
            "previousClose": CurrencyFormatter.formatNumber((arguments['sellPrice'] ?? 0.0) * 0.997, decimalPlaces: 2),
            "dailyHigh": CurrencyFormatter.formatNumber((arguments['sellPrice'] ?? 0.0) * 1.002, decimalPlaces: 2),
            "dailyLow": CurrencyFormatter.formatNumber((arguments['sellPrice'] ?? 0.0) * 0.996, decimalPlaces: 2),
            "weeklyPerformance": CurrencyFormatter.formatPercentageChange((arguments['change'] ?? 0.0) * 7),
            "weeklyIsPositive": arguments['isPositive'] ?? false,
          };
          _isLoading = false;
        });
        return;
      }
    }
    
    // Load data from API
    _loadCurrencyData(symbol);
  }
  
  // Check if the symbol is a gold product
  bool _isGoldProduct(String symbol) {
    // Check common gold product codes (both 3-letter codes and full names)
    final upperSymbol = symbol.toUpperCase();
    return upperSymbol.contains('ALTIN') || 
           upperSymbol.contains('GOLD') || 
           upperSymbol.contains('GRAM') ||
           upperSymbol.contains('CEYREK') ||
           upperSymbol.contains('YARIM') ||
           upperSymbol.contains('TAM') ||
           upperSymbol.contains('ATA') ||
           upperSymbol.contains('CUMHUR') ||
           upperSymbol.contains('22AYAR') ||
           upperSymbol.contains('18AYAR') ||
           upperSymbol.contains('14AYAR') ||
           upperSymbol.contains('GUMUS') ||
           upperSymbol.contains('ONSALTIN') ||
           // Check 3-letter gold codes
           upperSymbol == 'GRM' || // Gram Altın
           upperSymbol == 'CYR' || // Çeyrek Altın
           upperSymbol == 'YRM' || // Yarım Altın
           upperSymbol == 'TAM' || // Tam Altın
           upperSymbol == 'CMH' || // Cumhuriyet Altını
           upperSymbol == 'ATA' || // Ata Altın
           upperSymbol == 'ONS' || // Ons Altın
           upperSymbol == 'GMS' || // Gümüş
           upperSymbol == 'GRS' || // Gremse
           upperSymbol == 'BSL' || // Beşli
           upperSymbol == 'RST' || // Reşat
           upperSymbol == 'HMT';   // Hamit
  }

  Future<void> _loadCurrencyData(String symbol) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if this is a gold product
      if (_isGoldProduct(symbol)) {
        // Load gold product data
        final goldProducts = await GoldProductsService.getProductsWithPrices();
        
        // Find the specific gold product
        final goldData = goldProducts.firstWhere(
          (p) => p['code'] == symbol || (p['name']?.toString().toUpperCase().contains(symbol) ?? false),
          orElse: () => {
            'code': symbol,
            'name': _getCurrencyNameForSymbol(symbol),
            'buyPrice': 0.0,
            'sellPrice': 0.0,
            'change': 0.0,
            'isPositive': false,
          },
        );
        
        // Convert gold data to asset data format
        setState(() {
          assetData = {
            "symbol": goldData['code'] ?? symbol,
            "name": goldData['name'] ?? _getCurrencyNameForSymbol(symbol),
            "currentPrice": CurrencyFormatter.formatNumber(goldData['sellPrice'] ?? 0.0, decimalPlaces: 2),
            "buyPrice": goldData['buyPrice'] ?? 0.0,
            "sellPrice": goldData['sellPrice'] ?? 0.0,
            "priceChange": CurrencyFormatter.formatPercentageChange(goldData['change'] ?? 0.0).replaceAll('%', ''),
            "changePercent": CurrencyFormatter.formatPercentageChange(goldData['change'] ?? 0.0),
            "isPositive": goldData['isPositive'] ?? false,
            "openingPrice": CurrencyFormatter.formatNumber((goldData['sellPrice'] ?? 0.0) * 0.998, decimalPlaces: 2),
            "previousClose": CurrencyFormatter.formatNumber((goldData['sellPrice'] ?? 0.0) * 0.997, decimalPlaces: 2),
            "dailyHigh": CurrencyFormatter.formatNumber((goldData['sellPrice'] ?? 0.0) * 1.002, decimalPlaces: 2),
            "dailyLow": CurrencyFormatter.formatNumber((goldData['sellPrice'] ?? 0.0) * 0.996, decimalPlaces: 2),
            "weeklyPerformance": CurrencyFormatter.formatPercentageChange((goldData['change'] ?? 0.0) * 7),
            "weeklyIsPositive": goldData['isPositive'] ?? false,
            "weight_grams": goldData['weight_grams'],
            "buy_millesimal": goldData['buy_millesimal'],
            "sell_millesimal": goldData['sell_millesimal'],
          };
          _isLoading = false;
        });
        return;
      }
      
      // Get currency data from API (existing code for non-gold assets)
      final currencies = await _currencyApiService.getFormattedCurrencyData();
      
      // Find the specific currency
      Map<String, dynamic>? currencyData;
      try {
        currencyData = currencies.firstWhere(
          (c) => c['code'] == symbol,
        );
      } catch (e) {
        // Currency not found in API data
        currencyData = null;
      }
      
      if (currencyData == null) {
        // No data available - show error state
        if (mounted) {
          setState(() {
            _isLoading = false;
            assetData = null;
          });
        }
        return;
      }
      
      // Now currencyData is guaranteed to be non-null
      final validCurrencyData = currencyData;
      
      if (mounted) {
        setState(() {
          assetData = {
            "symbol": symbol,
            "name": _getCurrencyNameForSymbol(symbol),
            "currentPrice": CurrencyFormatter.formatSmartPrice(validCurrencyData['buyPrice'] as double),
            "priceChange": CurrencyFormatter.formatPercentageChange(validCurrencyData['change'] as double).replaceAll('%', ''),
            "changePercent": CurrencyFormatter.formatPercentageChange(validCurrencyData['change'] as double),
            "isPositive": validCurrencyData['isPositive'] as bool,
            "openingPrice": CurrencyFormatter.formatSmartPrice((validCurrencyData['buyPrice'] as double) * 0.99),
            "previousClose": CurrencyFormatter.formatSmartPrice((validCurrencyData['buyPrice'] as double) * 0.995),
            "dailyHigh": CurrencyFormatter.formatSmartPrice((validCurrencyData['buyPrice'] as double) * 1.01),
            "dailyLow": CurrencyFormatter.formatSmartPrice((validCurrencyData['buyPrice'] as double) * 0.99),
            "weeklyPerformance": CurrencyFormatter.formatPercentageChange((validCurrencyData['change'] as double) * 7),
            "weeklyIsPositive": validCurrencyData['isPositive'] as bool,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading currency data: $e');
      // Show error state
      if (mounted) {
        setState(() {
          assetData = null;
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
    WatchlistService.removeListener(_updateTicker);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if data is being fetched
    if (_isLoading || assetData == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFD700),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Dashboard header with back button and watchlist star
          DashboardHeader(
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
            rightWidget: IconButton(
              onPressed: () async {
                final symbol = assetData?['symbol'] ?? 'USD';
                final name = assetData?['name'] ?? 'USD/EUR';
                final currentPrice = double.tryParse(assetData?['currentPrice']?.toString().replaceAll(',', '.').replaceAll('€', '') ?? '1.0') ?? 1.0;
                
                final watchlistItem = {
                  'code': symbol,
                  'name': name,
                  'buyPrice': currentPrice,
                  'sellPrice': currentPrice + 0.01,
                  'change': 0.0,
                  'changePercent': 0.0,
                  'isPositive': true,
                };
                
                if (WatchlistService.isInWatchlist(symbol)) {
                  await WatchlistService.removeFromWatchlist(symbol);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name takip listesinden çıkarıldı'),
                      backgroundColor: AppTheme.negativeRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  await WatchlistService.addToWatchlist(watchlistItem);
                }
                setState(() {}); // Refresh UI
              },
              icon: Icon(
                WatchlistService.isInWatchlist(assetData?['symbol'] ?? '') 
                    ? Icons.bookmark 
                    : Icons.bookmark_border,
                color: Colors.white,
                size: 8.w,
              ),
              padding: EdgeInsets.all(2.w),
            ),
          ),

          // Price ticker with dark background extension
          Container(
            height: 29.w, // Fixed height for ticker container
            decoration: BoxDecoration(
              color: ThemeConfigService().primaryColor, // Dynamic primary color from admin panel
            ),
            child: Column(
              children: [
                const Expanded(
                  child: TickerSection(reduceBottomPadding: false),
                ),
                SizedBox(height: 0.5.h), // Extra dark space below ticker
              ],
            ),
          ),

          // Main content - scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  
                  // Asset info section
                  _buildAssetInfo(),

                  SizedBox(height: 2.h),

                  // Interactive chart with timeframe selector
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: InteractiveChartWidget(
                      assetSymbol: assetData!["symbol"] as String,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Key metrics cards
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: KeyMetricsWidget(
                      openingPrice: assetData!["openingPrice"] as String,
                      previousClose: assetData!["previousClose"] as String,
                      dailyHigh: assetData!["dailyHigh"] as String,
                      dailyLow: assetData!["dailyLow"] as String,
                      weeklyPerformance:
                          assetData!["weeklyPerformance"] as String,
                      weeklyIsPositive: assetData!["weeklyIsPositive"] as bool,
                    ),
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),

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
                onPressed: () async {
                  final symbol = assetData?['symbol'] ?? 'USD/TRY';
                  final name = assetData?['name'] ?? 'Amerikan Doları';
                  final currentPrice = double.tryParse(assetData?['currentPrice']?.toString().replaceAll(',', '') ?? '34.5958') ?? 34.5958;
                  
                  final watchlistItem = {
                    'code': symbol,
                    'name': name,
                    'buyPrice': currentPrice,
                    'sellPrice': currentPrice + 0.01,
                    'change': 0.0,
                    'changePercent': 0.0,
                    'isPositive': true,
                  };
                  
                  if (WatchlistService.isInWatchlist(symbol)) {
                    await WatchlistService.removeFromWatchlist(symbol);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name takip listesinden çıkarıldı'),
                        backgroundColor: AppTheme.negativeRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    await WatchlistService.addToWatchlist(watchlistItem);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name takip listesine eklendi'),
                        backgroundColor: AppTheme.positiveGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  setState(() {});
                },
                icon: Icon(
                  WatchlistService.isInWatchlist(assetData?['symbol'] ?? 'USD/TRY') 
                      ? Icons.bookmark 
                      : Icons.bookmark_border,
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

  Widget _buildAssetInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset name only - removed symbol
          Text(
            assetData!["name"] as String,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Price and change
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '€${assetData!["currentPrice"]}',
                    style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(
                        (assetData!["isPositive"] as bool) ? Icons.arrow_upward : Icons.arrow_downward,
                        color: (assetData!["isPositive"] as bool) ? AppTheme.positiveGreen : AppTheme.negativeRed,
                        size: 18,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        assetData!["changePercent"] as String,
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: (assetData!["isPositive"] as bool) ? AppTheme.positiveGreen : AppTheme.negativeRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

}
