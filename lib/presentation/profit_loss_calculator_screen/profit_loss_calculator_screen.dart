import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ticker_section.dart';
import '../../widgets/dashboard_header.dart';
import './widgets/time_period_dropdown_widget.dart';
import './widgets/amount_input_widget.dart';
import './widgets/currency_dropdown_widget.dart';
import './widgets/action_type_dropdown_widget.dart';
import './widgets/calculation_results_widget.dart';

class ProfitLossCalculatorScreen extends StatefulWidget {
  const ProfitLossCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<ProfitLossCalculatorScreen> createState() =>
      _ProfitLossCalculatorScreenState();
}

class _ProfitLossCalculatorScreenState
    extends State<ProfitLossCalculatorScreen> {
  final TextEditingController _amountController = TextEditingController();

  String _selectedPeriod = '30 Gün';
  String _selectedCurrency = 'USDEUR';
  String _selectedAction = 'Alsaydım';
  bool _isCalculating = false;
  bool _showResults = false;

  // Mock calculation results
  Map<String, dynamic>? _calculationResults;

  @override
  void initState() {
    super.initState();
    
    // Listen to theme changes
    ThemeConfigService().addListener(_onThemeChanged);
    _amountController.text = '1000';
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
  }

  void _updateTicker() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild with new theme colors
      });
    }
  }

  @override
  void dispose() {
    WatchlistService.removeListener(_updateTicker);
    ThemeConfigService().removeListener(_onThemeChanged);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _calculateProfitLoss() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen bir miktar girin'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    HapticFeedback.lightImpact();

    // Simulate calculation delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock calculation logic
    final amount = double.tryParse(_amountController.text) ?? 0;
    final periodDays = int.parse(_selectedPeriod.split(' ')[0]);

    // Mock historical rates (EUR as base currency)
    double pastRate = 1.0850;
    double currentRate = 1.0920;

    // Adjust rates based on currency (EUR as base)
    if (_selectedCurrency == 'TRYEUR') {
      pastRate = 0.0277;  // 1 TRY = 0.0277 EUR
      currentRate = 0.0271;  // 1 TRY = 0.0271 EUR
    } else if (_selectedCurrency == 'GBPEUR') {
      pastRate = 1.1820;
      currentRate = 1.1750;
    } else if (_selectedCurrency == 'JPYEUR') {
      pastRate = 0.00625;
      currentRate = 0.00635;
    }

    double pastValue = amount;
    double currentValue = amount;
    double profitLoss = 0;
    double profitLossPercentage = 0;

    if (_selectedAction == 'Alsaydım') {
      // If bought foreign currency with EUR
      pastValue = amount / pastRate;
      currentValue = pastValue * currentRate;
      profitLoss = currentValue - amount;
      profitLossPercentage = ((currentValue - amount) / amount) * 100;
    } else {
      // If sold foreign currency for EUR
      pastValue = amount * pastRate;
      currentValue = amount * currentRate;
      profitLoss = currentValue - pastValue;
      profitLossPercentage = ((currentValue - pastValue) / pastValue) * 100;
    }

    setState(() {
      _calculationResults = {
        'profitLoss': profitLoss,
        'profitLossPercentage': profitLossPercentage,
        'pastRate': pastRate,
        'currentRate': currentRate,
        'pastValue': pastValue,
        'currentValue': currentValue,
        'period': _selectedPeriod,
        'currency': _selectedCurrency,
        'action': _selectedAction,
        'amount': amount,
      };
      _isCalculating = false;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Compact Header with ZERDA branding
          const DashboardHeader(),

          // Price ticker
          // Price ticker with API data
          const TickerSection(reduceBottomPadding: false),

          // Main content with table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.scaffoldBackgroundColor,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input Form Section
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.shadowLight,
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time Period Dropdown
                        TimePeriodDropdownWidget(
                          selectedPeriod: _selectedPeriod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value!;
                              _showResults = false;
                            });
                          },
                        ),

                        SizedBox(height: 2.h),

                        // Amount Input
                        AmountInputWidget(
                          controller: _amountController,
                          onChanged: (value) {
                            setState(() {
                              _showResults = false;
                            });
                          },
                        ),

                        SizedBox(height: 2.h),

                        // Currency Dropdown
                        CurrencyDropdownWidget(
                          selectedCurrency: _selectedCurrency,
                          onChanged: (value) {
                            setState(() {
                              _selectedCurrency = value!;
                              _showResults = false;
                            });
                          },
                        ),

                        SizedBox(height: 2.h),

                        // Action Type Dropdown
                        ActionTypeDropdownWidget(
                          selectedAction: _selectedAction,
                          onChanged: (value) {
                            setState(() {
                              _selectedAction = value!;
                              _showResults = false;
                            });
                          },
                        ),
                      ],
                    ),
                    ),

                    SizedBox(height: 3.h),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                      onPressed: _isCalculating ? null : _calculateProfitLoss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.lightTheme.colorScheme.outline,
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isCalculating
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'HESAPLA',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    ),

                    SizedBox(height: 3.h),

                    // Results Section
                    if (_showResults && _calculationResults != null)
                      CalculationResultsWidget(
                        results: _calculationResults!,
                      ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/profit-loss-calculator-screen');
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCompactHeader() {
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
              // Hamburger menu button
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

              // KAR/ZARAR title
              Text(
                'KAR/ZARAR',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space to center the title
              SizedBox(width: 48), // Same width as menu button
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
        color: AppColors.tickerBackground,
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
  }}
