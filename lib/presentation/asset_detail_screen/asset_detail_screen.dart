import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/ticker_section.dart';
import './widgets/interactive_chart_widget.dart';
import './widgets/key_metrics_widget.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({Key? key}) : super(key: key);

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? assetData;

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
        return 34.5958;
      case 'EURTRY':
        return 37.4891;
      case 'GBPTRY':
        return 43.8056;
      case 'CHFTRY':
        return 39.2267;
      case 'AUDTRY':
        return 22.9012;
      case 'CADTRY':
        return 25.9501;
      case 'JPYTRY':
        return 0.2324;
      case 'SEKTRY':
        return 3.1267;
      case 'NOKTRY':
        return 3.0878;
      case 'DKKTRY':
        return 5.0267;
      case 'RUBTRY':
        return 0.3478;
      case 'CNYТRY':
        return 4.7267;
      case 'KRWTRY':
        return 0.0254;
      case 'SGDTRY':
        return 25.4789;
      case 'AEDTRY':
        return 9.4156;
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
        return 'American Dollar / Turkish Lira';
      case 'EURTRY':
        return 'Euro / Turkish Lira';
      case 'GBPTRY':
        return 'British Pound / Turkish Lira';
      case 'CHFTRY':
        return 'Swiss Franc / Turkish Lira';
      case 'AUDTRY':
        return 'Australian Dollar / Turkish Lira';
      case 'CADTRY':
        return 'Canadian Dollar / Turkish Lira';
      case 'JPYTRY':
        return 'Japanese Yen / Turkish Lira';
      case 'SEKTRY':
        return 'Swedish Krona / Turkish Lira';
      case 'NOKTRY':
        return 'Norwegian Krone / Turkish Lira';
      case 'DKKTRY':
        return 'Danish Krone / Turkish Lira';
      case 'RUBTRY':
        return 'Russian Ruble / Turkish Lira';
      case 'CNYТRY':
        return 'Chinese Yuan / Turkish Lira';
      case 'KRWTRY':
        return 'South Korean Won / Turkish Lira';
      case 'SGDTRY':
        return 'Singapore Dollar / Turkish Lira';
      case 'AEDTRY':
        return 'UAE Dirham / Turkish Lira';
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
        return 'Currency Pair / Turkish Lira';
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
    
    String symbol = 'USDTRY';
    if (arguments != null && arguments['code'] != null) {
      symbol = arguments['code'] as String;
    }
    
    // Generate asset data based on the symbol
    assetData = _getAssetDataTemplate(
      symbol, 
      _getCurrencyNameForSymbol(symbol)
    );
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
    // Show loading if assetData is not ready
    if (assetData == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header with ZERDA branding
          _buildHeader(),

          // Price ticker
          // Price ticker with API data
          const TickerSection(reduceBottomPadding: false),

          // Main content
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
          // Asset name and symbol
          Text(
            assetData!["name"] as String,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          Text(
            assetData!["symbol"] as String,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
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
                    '₺${assetData!["currentPrice"]}',
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
