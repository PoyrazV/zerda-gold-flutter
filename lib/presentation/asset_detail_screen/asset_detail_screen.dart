import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
import '../../services/gold_products_service.dart';
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

  // Default asset data template
  Map<String, dynamic> _getAssetDataTemplate(String symbol, String name) {
    // Generate mock data based on the selected currency
    final random = DateTime.now().millisecond;
    final basePrice = _getBasePriceForSymbol(symbol);
    final change = (random % 200 - 100) * 0.01;
    final isPositive = change > 0;
    
    return {
      "symbol": symbol,
      "name": name,
      "currentPrice": CurrencyFormatter.formatExchangeRate(basePrice),
      "priceChange": CurrencyFormatter.formatPercentageChange(change).replaceAll('%', ''),
      "changePercent": CurrencyFormatter.formatPercentageChange(change),
      "isPositive": isPositive,
      "openingPrice": CurrencyFormatter.formatExchangeRate(basePrice - (random % 100) * 0.001),
      "previousClose": CurrencyFormatter.formatExchangeRate(basePrice - (random % 50) * 0.002),
      "dailyHigh": CurrencyFormatter.formatExchangeRate(basePrice + (random % 80) * 0.001),
      "dailyLow": CurrencyFormatter.formatExchangeRate(basePrice - (random % 80) * 0.001),
      "weeklyPerformance": CurrencyFormatter.formatPercentageChange(change * 7),
      "weeklyIsPositive": isPositive,
    };
  }

  double _getBasePriceForSymbol(String symbol) {
    // Handle currency pairs with /EUR format
    switch (symbol) {
      // EUR-based currency pairs
      case 'USD/EUR':
      case 'USDEUR':
      case 'USD':
        return 0.9235;  // USD to EUR rate
      case 'GBP/EUR':
      case 'GBPEUR':
      case 'GBP':
        return 1.1682;  // GBP to EUR rate
      case 'CHF/EUR':
      case 'CHFEUR':
      case 'CHF':
        return 1.0456;  // CHF to EUR rate
      case 'AUD/EUR':
      case 'AUDEUR':
      case 'AUD':
        return 0.6109;  // AUD to EUR rate
      case 'CAD/EUR':
      case 'CADEUR':
      case 'CAD':
        return 0.6923;  // CAD to EUR rate
      case 'JPY/EUR':
      case 'JPYEUR':
      case 'JPY':
        return 0.0062;  // JPY to EUR rate
      case 'SEK/EUR':
      case 'SEKEUR':
      case 'SEK':
        return 0.0834;  // SEK to EUR rate
      case 'NOK/EUR':
      case 'NOKEUR':
      case 'NOK':
        return 0.0824;  // NOK to EUR rate
      case 'DKK/EUR':
      case 'DKKEUR':
      case 'DKK':
        return 0.1341;  // DKK to EUR rate
      case 'RUB/EUR':
      case 'RUBEUR':
      case 'RUB':
        return 0.0093;  // RUB to EUR rate
      case 'CNY/EUR':
      case 'CNYEUR':
      case 'CNY':
        return 0.1261;  // CNY to EUR rate
      case 'KRW/EUR':
      case 'KRWEUR':
      case 'KRW':
        return 0.0007;  // KRW to EUR rate
      case 'SGD/EUR':
      case 'SGDEUR':
      case 'SGD':
        return 0.6798;  // SGD to EUR rate
      case 'AED/EUR':
      case 'AEDEUR':
      case 'AED':
        return 0.2512;  // AED to EUR rate
      case 'TRY/EUR':
      case 'TRYEUR':
      case 'TRY':
        return 0.0267;  // TRY to EUR rate
      case 'EUR':
      case 'EURTRY':
        return 1.0000;  // EUR to EUR rate
      // Additional EUR-based currencies
      case 'PLN/EUR':
      case 'PLNEUR':
      case 'PLN':
        return 0.2332;  // PLN to EUR rate
      case 'HRK/EUR':
      case 'HRKEUR':
      case 'HRK':
        return 0.1313;  // HRK to EUR rate
      case 'CZK/EUR':
      case 'CZKEUR':
      case 'CZK':
        return 0.0384;  // CZK to EUR rate
      case 'HUF/EUR':
      case 'HUFEUR':
      case 'HUF':
        return 0.0025;  // HUF to EUR rate
      case 'BGN/EUR':
      case 'BGNEUR':
      case 'BGN':
        return 0.5120;  // BGN to EUR rate
      case 'RON/EUR':
      case 'RONEUR':
      case 'RON':
        return 0.2007;  // RON to EUR rate
      case 'ISK/EUR':
      case 'ISKEUR':
      case 'ISK':
        return 0.0066;  // ISK to EUR rate
      case 'THB/EUR':
      case 'THBEUR':
      case 'THB':
        return 0.0260;  // THB to EUR rate
      case 'MYR/EUR':
      case 'MYREUR':
      case 'MYR':
        return 0.1973;  // MYR to EUR rate
      case 'ZAR/EUR':
      case 'ZAREUR':
      case 'ZAR':
        return 0.0487;  // ZAR to EUR rate
      case 'INR/EUR':
      case 'INREUR':
      case 'INR':
        return 0.0109;  // INR to EUR rate
      case 'IDR/EUR':
      case 'IDREUR':
      case 'IDR':
        return 0.00006;  // IDR to EUR rate
      case 'PHP/EUR':
      case 'PHPEUR':
      case 'PHP':
        return 0.0162;  // PHP to EUR rate
      case 'MXN/EUR':
      case 'MXNEUR':
      case 'MXN':
        return 0.0529;  // MXN to EUR rate
      case 'BRL/EUR':
      case 'BRLEUR':
      case 'BRL':
        return 0.1810;  // BRL to EUR rate
      // Gold types in EUR
      case 'GRAM':
        return 75.91;  // Gram gold in EUR
      case 'YÇEYREK':
        return 77.11;  // Quarter gold in EUR
      case 'EÇEYREK':
        return 76.27;  // Old quarter gold in EUR
      case 'YYARIM':
        return 154.23;  // Half gold in EUR
      case 'EYARIM':
        return 152.55;  // Old half gold in EUR
      case 'YTAM':
        return 308.45;  // Full gold in EUR
      case 'ETAM':
        return 305.11;  // Old full gold in EUR
      case 'YATA':
        return 493.58;  // Ata gold in EUR
      case 'EATA':
        return 488.18;  // Old Ata gold in EUR
      case 'CUMHUR':
        return 513.20;  // Republic gold in EUR
      case '22AYAR':
        return 71.17;  // 22 karat in EUR
      case '18AYAR':
        return 58.09;  // 18 karat in EUR
      case '14AYAR':
        return 45.29;  // 14 karat in EUR
      case 'GUMUS':
        return 0.91;  // Silver in EUR
      case 'ONSALTIN':
        return 73.25;  // Ounce gold in EUR
      default:
        return 0.9235; // Default USD/EUR
    }
  }

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
      // Gold types
      case 'GRAM':
        return 'Gram Altın';
      case 'YÇEYREK':
        return 'Yeni Çeyrek Altın';
      case 'EÇEYREK':
        return 'Eski Çeyrek Altın';
      case 'YYARIM':
        return 'Yeni Yarım Altın';
      case 'EYARIM':
        return 'Eski Yarım Altın';
      case 'YTAM':
        return 'Yeni Tam Altın';
      case 'ETAM':
        return 'Eski Tam Altın';
      case 'YATA':
        return 'Yeni Ata Altın';
      case 'EATA':
        return 'Eski Ata Altın';
      case 'CUMHUR':
        return 'Cumhuriyet Altını';
      case '22AYAR':
        return '22 Ayar Bilezik';
      case '18AYAR':
        return '18 Ayar Bilezik';
      case '14AYAR':
        return '14 Ayar Bilezik';
      case 'GUMUS':
        return 'Gümüş (Gram)';
      case 'ONSALTIN':
        return 'Ons Altın (USD)';
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
    // Check common gold product codes
    return symbol.contains('ALTIN') || 
           symbol.contains('GOLD') || 
           symbol.contains('GRAM') ||
           symbol.contains('CEYREK') ||
           symbol.contains('YARIM') ||
           symbol.contains('TAM') ||
           symbol.contains('ATA') ||
           symbol.contains('CUMHUR') ||
           symbol.contains('22AYAR') ||
           symbol.contains('18AYAR') ||
           symbol.contains('14AYAR') ||
           symbol.contains('GUMUS') ||
           symbol.contains('ONSALTIN');
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
      final currencyData = currencies.firstWhere(
        (c) => c['code'] == symbol,
        orElse: () => {
          'code': symbol,
          'name': symbol,
          'buyPrice': _getBasePriceForSymbol(symbol),
          'sellPrice': _getBasePriceForSymbol(symbol) * 1.002,
          'change': 0.45,
          'isPositive': true,
        },
      );
      
      if (mounted) {
        setState(() {
          assetData = {
            "symbol": symbol,
            "name": _getCurrencyNameForSymbol(symbol),
            "currentPrice": CurrencyFormatter.formatSmartPrice(currencyData['buyPrice'] as double),
            "priceChange": CurrencyFormatter.formatPercentageChange(currencyData['change'] as double).replaceAll('%', ''),
            "changePercent": CurrencyFormatter.formatPercentageChange(currencyData['change'] as double),
            "isPositive": currencyData['isPositive'] as bool,
            "openingPrice": CurrencyFormatter.formatSmartPrice((currencyData['buyPrice'] as double) * 0.99),
            "previousClose": CurrencyFormatter.formatSmartPrice((currencyData['buyPrice'] as double) * 0.995),
            "dailyHigh": CurrencyFormatter.formatSmartPrice((currencyData['buyPrice'] as double) * 1.01),
            "dailyLow": CurrencyFormatter.formatSmartPrice((currencyData['buyPrice'] as double) * 0.99),
            "weeklyPerformance": CurrencyFormatter.formatPercentageChange((currencyData['change'] as double) * 7),
            "weeklyIsPositive": currencyData['isPositive'] as bool,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading currency data: $e');
      // Fallback to template data
      if (mounted) {
        setState(() {
          assetData = _getAssetDataTemplate(symbol, _getCurrencyNameForSymbol(symbol));
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
              onPressed: () {
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
                  WatchlistService.removeFromWatchlist(symbol);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name takip listesinden çıkarıldı'),
                      backgroundColor: AppTheme.negativeRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  WatchlistService.addToWatchlist(watchlistItem);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name takip listesine eklendi'),
                      backgroundColor: AppTheme.positiveGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
            decoration: const BoxDecoration(
              color: Color(0xFF18214F), // Dark navy background
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
                onPressed: () {
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
                    WatchlistService.removeFromWatchlist(symbol);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name takip listesinden çıkarıldı'),
                        backgroundColor: AppTheme.negativeRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    WatchlistService.addToWatchlist(watchlistItem);
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
