import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/ticker_section.dart';
import './widgets/amount_input_widget.dart';
import './widgets/currency_picker_bottom_sheet.dart';
import './widgets/currency_selector_widget.dart';
import './widgets/quick_converter_widget.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _fromAmountController = TextEditingController();
  final TextEditingController _toAmountController = TextEditingController();

  late AnimationController _swapAnimationController;
  late Animation<double> _swapAnimation;
  
  // API Services
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  
  // API Data Storage
  Map<String, dynamic> _currencyRates = {};
  List<Map<String, dynamic>> _goldPrices = [];
  bool _isLoadingRates = false;

  Map<String, dynamic> _fromCurrency = {
    "code": "EUR",
    "name": "Euro",
    "flag": "https://flagcdn.com/w320/eu.png",
    "symbol": "€"
  };

  Map<String, dynamic> _toCurrency = {
    "code": "USD",
    "name": "Amerikan Doları",
    "flag": "https://flagcdn.com/w320/us.png",
    "symbol": "\$"
  };

  double _exchangeRate = 1.0; // Will be calculated after API loads
  double _changePercentage = 0.0;
  DateTime _lastUpdate = DateTime.now();


  @override
  void initState() {
    super.initState();
    _swapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swapAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swapAnimationController,
      curve: Curves.easeInOut,
    ));

    _fromAmountController.addListener(_onFromAmountChanged);
    _fromAmountController.text = '1';
    
    // Load API data and update initial exchange rate
    _loadApiData();
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
  }

  void _updateTicker() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadApiData() async {
    setState(() {
      _isLoadingRates = true;
    });

    try {
      // Load currency rates
      final currencyData = await _currencyApiService.getLatestRates();
      if (currencyData != null && currencyData['rates'] != null) {
        _currencyRates = Map<String, dynamic>.from(currencyData['rates']);
        // Add TRY itself with rate 1.0 for TRY to TRY conversions
        _currencyRates['TRY'] = 1.0;
      }

      // Gold prices artık kullanılmıyor - sadece currency API kullanıyoruz
      _goldPrices = [];

    } catch (e) {
      print('Error loading API data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRates = false;
          _updateExchangeRate();
          _calculateConversion();
        });
      }
    }
  }

  @override
  void dispose() {
    WatchlistService.removeListener(_updateTicker);
    _fromAmountController.dispose();
    _toAmountController.dispose();
    _swapAnimationController.dispose();
    super.dispose();
  }

  void _onFromAmountChanged() {
    _calculateConversion();
  }

  void _calculateConversion() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0.0;
    final toAmount = fromAmount * _exchangeRate;
    _toAmountController.text = CurrencyFormatter.formatNumber(toAmount);
  }

  void _swapCurrencies() {
    HapticFeedback.lightImpact();
    _swapAnimationController.forward().then((_) {
      setState(() {
        final temp = _fromCurrency;
        _fromCurrency = _toCurrency;
        _toCurrency = temp;

        // Recalculate exchange rate for swapped currencies
        _updateExchangeRate();
        
        // Keep the same value in the from field
        final currentFromValue = _fromAmountController.text;
        _fromAmountController.text = currentFromValue;
        _calculateConversion();
      });
      _swapAnimationController.reset();
    });
  }

  void _showCurrencyPicker({required bool isFromCurrency}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencyPickerBottomSheet(
        selectedCurrency:
            isFromCurrency ? _fromCurrency['code'] : _toCurrency['code'],
        onCurrencySelected: (currency) {
          setState(() {
            if (isFromCurrency) {
              _fromCurrency = currency;
            } else {
              _toCurrency = currency;
            }
            _updateExchangeRate();
            _calculateConversion();
          });
        },
      ),
    );
  }

  void _updateExchangeRate() {
    final fromCode = _fromCurrency['code'] as String;
    final toCode = _toCurrency['code'] as String;

    try {
      _exchangeRate = _calculateRealExchangeRate(fromCode, toCode);
      _changePercentage = _calculateChangePercentage(fromCode, toCode);
    } catch (e) {
      print('Error calculating exchange rate: $e');
      // Fallback to default
      _exchangeRate = 1.0;
      _changePercentage = 0.0;
    }

    _lastUpdate = DateTime.now();
  }

  double _calculateRealExchangeRate(String fromCode, String toCode) {
    // Handle gold currencies
    final goldCodes = ['GRAM', 'ÇEYREK', 'YARIM', 'TAM', 'ONS'];
    final isFromGold = goldCodes.contains(fromCode);
    final isToGold = goldCodes.contains(toCode);

    if (isFromGold && isToGold) {
      // Gold to Gold conversions
      final fromPrice = _getGoldPrice(fromCode);
      final toPrice = _getGoldPrice(toCode);
      if (fromPrice > 0 && toPrice > 0) {
        return fromPrice / toPrice;
      }
    } else if (isFromGold && !isToGold) {
      // Gold to Currency
      final goldPrice = _getGoldPrice(fromCode);
      if (goldPrice > 0) {
        if (toCode == 'TRY') {
          return goldPrice; // Gold price is already in TRY
        } else {
          // Convert gold to TRY, then TRY to target currency
          final tryToTargetRate = _getCurrencyRate('TRY', toCode);
          return goldPrice * tryToTargetRate;
        }
      }
    } else if (!isFromGold && isToGold) {
      // Currency to Gold
      final goldPrice = _getGoldPrice(toCode);
      if (goldPrice > 0) {
        if (fromCode == 'TRY') {
          return 1.0 / goldPrice; // 1 TRY = ? gold
        } else {
          // Convert source currency to TRY, then TRY to gold
          final sourceToTryRate = _getCurrencyRate(fromCode, 'TRY');
          return sourceToTryRate / goldPrice;
        }
      }
    } else {
      // Currency to Currency
      return _getCurrencyRate(fromCode, toCode);
    }

    // Fallback
    return 1.0;
  }

  double _getCurrencyRate(String fromCode, String toCode) {
    if (fromCode == toCode) return 1.0;
    
    if (_currencyRates.isEmpty) {
      // Fallback to hardcoded rates if API data not available
      return _getFallbackCurrencyRate(fromCode, toCode);
    }

    // API provides rates with TRY as base
    // rates[USD] = how many USD for 1 TRY (e.g., 0.029 means 1 TRY = 0.029 USD)
    // To get USD/TRY rate (how many TRY for 1 USD), we need 1 / rates[USD]
    
    if (fromCode == 'TRY') {
      // TRY to other currency
      // 1 TRY = rates[toCode] target currency
      final rate = _currencyRates[toCode];
      return rate?.toDouble() ?? _getFallbackCurrencyRate(fromCode, toCode);
    } else if (toCode == 'TRY') {
      // Other currency to TRY
      // 1 source currency = 1/rates[fromCode] TRY
      final rate = _currencyRates[fromCode];
      if (rate != null && rate != 0) {
        return 1.0 / rate.toDouble();
      }
      return _getFallbackCurrencyRate(fromCode, toCode);
    } else {
      // Currency to Currency (via TRY)
      // Convert from source to TRY, then TRY to target
      final fromRate = _currencyRates[fromCode]; // 1 TRY = fromRate source
      final toRate = _currencyRates[toCode];     // 1 TRY = toRate target
      
      if (fromRate != null && toRate != null && fromRate != 0) {
        // 1 source = (1/fromRate) TRY
        // (1/fromRate) TRY = (1/fromRate) * toRate target
        // Therefore: 1 source = toRate/fromRate target
        return toRate.toDouble() / fromRate.toDouble();
      }
    }

    return _getFallbackCurrencyRate(fromCode, toCode);
  }

  double _getGoldPrice(String goldCode) {
    // Map converter gold codes to API codes
    final goldMapping = {
      'GRAM': 'ALTIN',
      'ÇEYREK': 'CEYREK_YENI',
      'YARIM': 'YARIM_YENI',
      'TAM': 'TAM_YENI',
      'ONS': 'PLATIN', // Using platinum as ounce reference
    };

    final apiCode = goldMapping[goldCode];
    if (apiCode == null) return 0.0;

    final goldData = _goldPrices.firstWhere(
      (item) => item['code'] == apiCode,
      orElse: () => <String, dynamic>{},
    );

    // Use average of buy and sell price
    final buyPrice = goldData['buyPrice']?.toDouble() ?? 0.0;
    final sellPrice = goldData['sellPrice']?.toDouble() ?? 0.0;
    return (buyPrice + sellPrice) / 2.0;
  }

  double _getFallbackCurrencyRate(String fromCode, String toCode) {
    // Fallback hardcoded rates when API is not available
    final fallbackRates = {
      'USDTRY': 34.60,
      'EURTRY': 37.50,
      'GBPTRY': 43.80,
      'CHFTRY': 39.20,
      'AUDTRY': 22.90,
      'CADTRY': 25.95,
      'JPYTRY': 0.23,
    };

    final pairKey = '${fromCode}${toCode}';
    if (fallbackRates.containsKey(pairKey)) {
      return fallbackRates[pairKey]!;
    }

    final reversePairKey = '${toCode}${fromCode}';
    if (fallbackRates.containsKey(reversePairKey)) {
      return 1.0 / fallbackRates[reversePairKey]!;
    }

    return 1.0;
  }

  double _calculateChangePercentage(String fromCode, String toCode) {
    // For now, return a small random change percentage
    // In a real app, you would compare with previous rates
    final seed = fromCode.hashCode + toCode.hashCode + DateTime.now().hour;
    return ((seed % 200 - 100) / 100.0) * 2.0; // -2% to +2%
  }

  void _onQuickAmountSelected(double amount) {
    _fromAmountController.text = CurrencyFormatter.formatNumber(amount, decimalPlaces: 0);
    _calculateConversion();
  }


  void _shareConversion() {
    final fromAmount = _fromAmountController.text;
    final toAmount = _toAmountController.text;
    final fromCode = _fromCurrency['code'];
    final toCode = _toCurrency['code'];

    final shareText = '$fromAmount $fromCode = $toAmount $toCode\n'
        'Kur: 1 $fromCode = ${CurrencyFormatter.formatExchangeRate(_exchangeRate)} $toCode\n';

    // In a real app, you would use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paylaşım özelliği: $shareText'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding
          const DashboardHeader(),

          // Spacer between logo and ticker
          Container(
            decoration: BoxDecoration(
              color: DynamicThemeColors.primaryColor, // Dynamic primary color
            ),
          ),

          // Price ticker with API data
          const TickerSection(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Add spacing between header/ticker and content
                    SizedBox(height: 1.5.h),
                    
                    // Loading indicator for API data
                    if (_isLoadingRates)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Güncel kurlar yükleniyor...',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // From amount input
                    AmountInputWidget(
                      controller: _fromAmountController,
                      currencyCode: _fromCurrency['code'] as String,
                      onChanged: (value) => _calculateConversion(),
                    ),

                    SizedBox(height: 2.h),

                    // Swap button with currency selectors on sides
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // From currency selector (left side)
                        CurrencySelectorWidget(
                          currencyCode: _fromCurrency['code'] as String,
                          flagUrl: _fromCurrency['flag'] as String,
                          onTap: () =>
                              _showCurrencyPicker(isFromCurrency: true),
                        ),
                        
                        // Swap button (center)
                        GestureDetector(
                          onTap: _swapCurrencies,
                          child: AnimatedBuilder(
                            animation: _swapAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _swapAnimation.value * 3.14159,
                                child: Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: BoxDecoration(
                                    color: DynamicThemeColors.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.shadowLight,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Transform.rotate(
                                    angle: 1.5708, // 90 degrees in radians (π/2)
                                    child: CustomIconWidget(
                                      iconName: 'swap_vert',
                                      color: const Color(0xFFE8D095),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // To currency selector (right side)
                        CurrencySelectorWidget(
                          currencyCode: _toCurrency['code'] as String,
                          flagUrl: _toCurrency['flag'] as String,
                          onTap: () =>
                              _showCurrencyPicker(isFromCurrency: false),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // To amount input (read-only)
                    AmountInputWidget(
                      controller: _toAmountController,
                      currencyCode: _toCurrency['code'] as String,
                      isReadOnly: true,
                    ),

                    SizedBox(height: 3.h),

                    // Quick converter
                    QuickConverterWidget(
                      fromCurrency: _fromCurrency['code'] as String,
                      toCurrency: _toCurrency['code'] as String,
                      exchangeRate: _exchangeRate,
                      onAmountSelected: _onQuickAmountSelected,
                    ),

                    SizedBox(height: 4.h),
                ],
              ),
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

              // Empty space for symmetry
              SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/currency-converter-screen');
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

    return Column(
      children: [
        Container(
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
        ),
        SizedBox(height: 2.h),
      ],
    );
  }
}
