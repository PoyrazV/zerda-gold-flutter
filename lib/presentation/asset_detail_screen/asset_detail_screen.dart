import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
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
    switch (symbol) {
      // Currency pairs
      case 'USDTRY':
      case 'USD':
        return 34.5958;
      case 'EURTRY':
      case 'EUR':
        return 37.4891;
      case 'GBPTRY':
      case 'GBP':
        return 43.8056;
      case 'CHFTRY':
      case 'CHF':
        return 39.2267;
      case 'AUDTRY':
      case 'AUD':
        return 22.9012;
      case 'CADTRY':
      case 'CAD':
        return 25.9501;
      case 'JPYTRY':
      case 'JPY':
        return 0.2324;
      case 'SEKTRY':
      case 'SEK':
        return 3.1267;
      case 'NOKTRY':
      case 'NOK':
        return 3.0878;
      case 'DKKTRY':
      case 'DKK':
        return 5.0267;
      case 'RUBTRY':
      case 'RUB':
        return 0.3478;
      case 'CNYTRY':
      case 'CNY':
        return 4.7267;
      case 'KRWTRY':
      case 'KRW':
        return 0.0254;
      case 'SGDTRY':
      case 'SGD':
        return 25.4789;
      case 'AEDTRY':
      case 'AED':
        return 9.4156;
      // Additional currencies that might come from Dashboard
      case 'PLN':
        return 8.7456;
      case 'HRK':
        return 5.1234;
      case 'CZK':
        return 1.5678;
      case 'HUF':
        return 0.0987;
      case 'BGN':
        return 19.2345;
      case 'RON':
        return 7.6543;
      case 'ISK':
        return 0.2567;
      case 'THB':
        return 1.0234;
      case 'MYR':
        return 7.8901;
      case 'ZAR':
        return 1.9234;
      case 'INR':
        return 0.4156;
      case 'IDR':
        return 0.0022;
      case 'PHP':
        return 0.6234;
      case 'MXN':
        return 2.0156;
      case 'BRL':
        return 7.1234;
      // Gold types
      case 'GRAM':
        return 2654.30;
      case 'YÇEYREK':
        return 2891.75;
      case 'EÇEYREK':
        return 2860.40;
      case 'YYARIM':
        return 5783.50;
      case 'EYARIM':
        return 5720.80;
      case 'YTAM':
        return 11567.00;
      case 'ETAM':
        return 11441.60;
      case 'YATA':
        return 11485.75;
      case 'EATA':
        return 11362.40;
      case 'CUMHUR':
        return 11610.30;
      case '22AYAR':
        return 2668.75;
      case '18AYAR':
        return 2178.25;
      case '14AYAR':
        return 1698.50;
      case 'GUMUS':
        return 34.25;
      case 'ONSALTIN':
        return 2746.85;
      default:
        return 34.5958; // Default USD/TRY
    }
  }

  String _getCurrencyNameForSymbol(String symbol) {
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
    }
    
    // Load data from API
    _loadCurrencyData(symbol);
  }
  
  Future<void> _loadCurrencyData(String symbol) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get currency data from API
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
            "currentPrice": CurrencyFormatter.formatNumber(currencyData['buyPrice'] as double, decimalPlaces: 4),
            "priceChange": CurrencyFormatter.formatPercentageChange(currencyData['change'] as double).replaceAll('%', ''),
            "changePercent": CurrencyFormatter.formatPercentageChange(currencyData['change'] as double),
            "isPositive": currencyData['isPositive'] as bool,
            "openingPrice": CurrencyFormatter.formatNumber((currencyData['buyPrice'] as double) * 0.99, decimalPlaces: 4),
            "previousClose": CurrencyFormatter.formatNumber((currencyData['buyPrice'] as double) * 0.995, decimalPlaces: 4),
            "dailyHigh": CurrencyFormatter.formatNumber((currencyData['buyPrice'] as double) * 1.01, decimalPlaces: 4),
            "dailyLow": CurrencyFormatter.formatNumber((currencyData['buyPrice'] as double) * 0.99, decimalPlaces: 4),
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
