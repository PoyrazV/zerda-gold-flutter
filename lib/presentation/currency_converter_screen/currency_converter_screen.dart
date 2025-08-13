import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/price_ticker.dart';
import '../../widgets/app_header.dart';
import './widgets/amount_input_widget.dart';
import './widgets/currency_picker_bottom_sheet.dart';
import './widgets/currency_selector_widget.dart';
import './widgets/exchange_rate_widget.dart';
import './widgets/price_ticker_widget.dart';
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

  Map<String, dynamic> _fromCurrency = {
    "code": "USD",
    "name": "Amerikan Doları",
    "flag": "https://flagcdn.com/w320/us.png",
    "symbol": "\$"
  };

  Map<String, dynamic> _toCurrency = {
    "code": "GOLD_GRAM",
    "name": "Gram Altın",
    "flag": "https://cdn-icons-png.flaticon.com/512/2583/2583788.png",
    "symbol": "gr"
  };

  double _exchangeRate = 32.4567 / 2654.30; // USD to Gold Gram
  double _changePercentage = 1.10;
  DateTime _lastUpdate = DateTime.now().subtract(const Duration(minutes: 2));


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
    _calculateConversion();
    
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

        // Update exchange rate (inverse)
        _exchangeRate = 1 / _exchangeRate;
        _changePercentage = -_changePercentage;

        // Swap amounts
        final tempAmount = _fromAmountController.text;
        _fromAmountController.text = _toAmountController.text;
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
    // Mock exchange rate update based on currency pair
    final fromCode = _fromCurrency['code'] as String;
    final toCode = _toCurrency['code'] as String;

    // Currency to Currency rates
    if (fromCode == 'USD' && toCode == 'TRY') {
      _exchangeRate = 32.4567;
      _changePercentage = 0.45;
    } else if (fromCode == 'EUR' && toCode == 'TRY') {
      _exchangeRate = 35.2134;
      _changePercentage = -0.23;
    } else if (fromCode == 'TRY' && toCode == 'USD') {
      _exchangeRate = 0.0308;
      _changePercentage = -0.45;
    } else if (fromCode == 'EUR' && toCode == 'USD') {
      _exchangeRate = 1.0856;
      _changePercentage = 0.12;
    }
    // Currency to Gold rates (TRY to Gold)
    else if (fromCode == 'TRY' && toCode == 'GOLD_GRAM') {
      _exchangeRate = 1 / 2654.30; // 1 TRY = ? gram gold
      _changePercentage = 0.65;
    } else if (fromCode == 'TRY' && toCode == 'GOLD_QUARTER') {
      _exchangeRate = 1 / 2891.75; // 1 TRY = ? quarter gold
      _changePercentage = 0.85;
    } else if (fromCode == 'TRY' && toCode == 'GOLD_HALF') {
      _exchangeRate = 1 / 5783.50; // 1 TRY = ? half gold
      _changePercentage = 1.12;
    } else if (fromCode == 'TRY' && toCode == 'GOLD_FULL') {
      _exchangeRate = 1 / 11567.00; // 1 TRY = ? full gold
      _changePercentage = 0.95;
    } else if (fromCode == 'TRY' && toCode == 'GOLD_OUNCE') {
      _exchangeRate = 1 / 2746.85; // 1 TRY = ? ounce gold (USD)
      _changePercentage = -0.25;
    }
    // Gold to Currency rates (Gold to TRY)
    else if (fromCode == 'GOLD_GRAM' && toCode == 'TRY') {
      _exchangeRate = 2654.30; // 1 gram gold = ? TRY
      _changePercentage = 0.65;
    } else if (fromCode == 'GOLD_QUARTER' && toCode == 'TRY') {
      _exchangeRate = 2891.75; // 1 quarter gold = ? TRY
      _changePercentage = 0.85;
    } else if (fromCode == 'GOLD_HALF' && toCode == 'TRY') {
      _exchangeRate = 5783.50; // 1 half gold = ? TRY
      _changePercentage = 1.12;
    } else if (fromCode == 'GOLD_FULL' && toCode == 'TRY') {
      _exchangeRate = 11567.00; // 1 full gold = ? TRY
      _changePercentage = 0.95;
    } else if (fromCode == 'GOLD_OUNCE' && toCode == 'TRY') {
      _exchangeRate = 2746.85 * 32.4567; // 1 ounce gold = ? TRY (via USD)
      _changePercentage = -0.25;
    }
    // Gold to Gold conversions
    else if (fromCode == 'GOLD_GRAM' && toCode == 'GOLD_QUARTER') {
      _exchangeRate = 2654.30 / 2891.75;
      _changePercentage = 0.20;
    } else if (fromCode == 'GOLD_QUARTER' && toCode == 'GOLD_GRAM') {
      _exchangeRate = 2891.75 / 2654.30;
      _changePercentage = -0.20;
    }
    // USD to Gold rates
    else if (fromCode == 'USD' && toCode == 'GOLD_GRAM') {
      _exchangeRate = 32.4567 / 2654.30; // USD to TRY to Gold
      _changePercentage = 1.10;
    } else if (fromCode == 'USD' && toCode == 'GOLD_OUNCE') {
      _exchangeRate = 1 / 2746.85; // 1 USD = ? ounce gold
      _changePercentage = 0.70;
    }
    // Default fallback
    else {
      _exchangeRate = 1.0;
      _changePercentage = 0.0;
    }

    _lastUpdate = DateTime.now();
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
        'Kur: 1 $fromCode = ${CurrencyFormatter.formatExchangeRate(_exchangeRate)} $toCode\n'
        'FinTracker Pro ile hesaplandı';

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
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding
          AppHeader(textTopPadding: 1.0.h),

          // Price ticker with API data
          const PriceTicker(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
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
                                      color:
                                          AppTheme.lightTheme.colorScheme.onPrimary,
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
