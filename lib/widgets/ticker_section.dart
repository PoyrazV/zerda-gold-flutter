
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_export.dart';
import '../services/currency_api_service.dart';
import '../services/watchlist_service.dart';
import '../services/theme_config_service.dart';

class TickerSection extends StatefulWidget {
  final bool reduceBottomPadding;
  
  const TickerSection({Key? key, this.reduceBottomPadding = false}) : super(key: key);

  @override
  State<TickerSection> createState() => _TickerSectionState();
}

class _TickerSectionState extends State<TickerSection> {
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  final ThemeConfigService _themeConfigService = ThemeConfigService();
  List<Map<String, dynamic>> _tickerData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ThemeConfigService().addListener(_onThemeChanged);
    _loadTickerData();
    // Listen to watchlist changes
    WatchlistService.addListener(_updateTicker);
  }
  
  @override
  void dispose() {
    WatchlistService.removeListener(_updateTicker);
    ThemeConfigService().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild with new theme colors
      });
    }
  }
  
  void _updateTicker() {
    if (mounted) {
      _loadTickerData();
    }
  }

  Future<void> _loadTickerData() async {
    // Set loading state
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    // Small delay to ensure UserDataService has loaded
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Get watchlist items
    final watchlistItems = WatchlistService.getWatchlistItems();
    print('🎯 TickerSection: Loading ticker data, watchlist items: ${watchlistItems.length}');
    
    if (watchlistItems.isNotEmpty) {
      // Use watchlist items for ticker
      if (mounted) {
        setState(() {
          _tickerData = watchlistItems.take(10).toList(); // Limit to 10 items
          _isLoading = false;
        });
      }
      print('✅ TickerSection: Loaded ${_tickerData.length} items from watchlist');
    } else {
      // When watchlist is empty, try to get data from API
      try {
        // Get real data from API
        final currencies = await _currencyApiService.getFormattedCurrencyData();
        if (mounted) {
          setState(() {
            // Show first few currencies from API if available
            _tickerData = currencies.take(5).toList();
            _isLoading = false;
          });
        }
        print('✅ TickerSection: Loaded ${_tickerData.length} items from API (watchlist empty)');
      } catch (e) {
        // On error, show empty state
        if (mounted) {
          setState(() {
            _tickerData = [];
            _isLoading = false;
          });
        }
        print('❌ TickerSection: Error loading ticker data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27.w, // Reduced height to decrease spacing
      decoration: BoxDecoration(
        color: AppColors.tickerBackground,
      ),
      padding: EdgeInsets.only(bottom: widget.reduceBottomPadding ? 0.5.w : 2.w), // Conditional bottom padding
      child: _tickerData.isEmpty && _isLoading
          ? Center(
              child: SizedBox(
                width: 5.w,
                height: 5.w,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              ),
            )
          : _tickerData.isEmpty
          ? Center(
              child: Text(
                'Takip listesi boş',
                style: GoogleFonts.inter(
                  fontSize: 3.5.w,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gold.withValues(alpha: 0.7),
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              itemCount: _tickerData.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == _tickerData.length) {
                  return _buildAddTickerCard();
                }
                final currency = _tickerData[index];
                return _buildTickerCard(currency);
              },
            ),
    );
  }

  Widget _buildAddTickerCard() {
    return Container(
      width: 26.5.w, // Same width as ticker cards
      height: 22.w, // Same height as ticker cards
      margin: EdgeInsets.only(right: 2.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Same background as ticker cards
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0x1A6B7280), // Same border as ticker cards
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/asset-selection-screen');
        },
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 6.w,
                color: const Color(0xFF4B5563),
              ),
              SizedBox(height: 1.w),
              Text(
                'EKLE',
                style: GoogleFonts.inter(
                  fontSize: 3.w,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTickerCard(Map<String, dynamic> currency) {
    final bool isPositive = (currency['isPositive'] as bool?) ?? false;
    final double change = (currency['change'] as num?)?.toDouble() ?? 0.0;
    
    return GestureDetector(
      onTap: () {
        // Navigate to asset detail screen with complete currency data
        Navigator.pushNamed(
          context,
          '/asset-detail-screen',
          arguments: {
            'code': currency['code'] as String,
            'name': currency['name'] as String?,
            'buyPrice': currency['buyPrice'],
            'sellPrice': currency['sellPrice'],
            'change': currency['change'],
            'isPositive': currency['isPositive'],
          },
        );
      },
      child: Container(
        width: 26.5.w, // Further increased width for larger text
        height: 22.w, // Moderate height for balanced spacing
        margin: EdgeInsets.only(right: 2.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), // Light gray background (original)
          borderRadius: BorderRadius.circular(8), // 0.5rem equivalent
          border: Border.all(
            color: const Color(0x1A6B7280), // #6B72801A (semi-transparent gray)
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(2.5.w), // Further reduced padding
        child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between elements
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        children: [
          // Top section - Product name and price close together
          SizedBox(height: 0.5.w), // Üstten boşluk - USD/EUR'u aşağı iter
          Column(
            children: [
              // Product name
              Text(
                (currency['name'] as String?) ?? 'Unknown',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700,
                  fontSize: 3.3.w, // Increased font size for better readability
                  color: const Color(0xFF4B5563), // Original gray text
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center, // Center align text
              ),
              
              SizedBox(height: 4.w), // Small spacing between name and price
              
              // Price
              Text(
                CurrencyFormatter.formatSmartPrice((currency['sellPrice'] as num?)?.toDouble() ?? 0.0),
                style: GoogleFonts.inter(fontWeight: FontWeight.w900,
                  fontSize: 3.5.w, // Increased font size for better readability
                  color: const Color(0xFF4B5563), // Darker gray for better visibility
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center, // Center align text
              ),
            ],
          ),
          
          // Bottom section - Change percentage container
          Container(
                padding: EdgeInsets.symmetric(horizontal: 0.5.w, vertical: 0.3.w),
                decoration: BoxDecoration(
                  color: isPositive 
                      ? _themeConfigService.listPrimaryColor
                      : _themeConfigService.listSecondaryColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPositive 
                        ? _themeConfigService.listPrimaryBorder.withOpacity(0.2)
                        : _themeConfigService.listSecondaryBorder.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '%${change.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                      fontSize: 2.7.w, // Increased font size to match list
                      fontWeight: FontWeight.w500, // Medium weight to match list
                      color: isPositive 
                          ? _themeConfigService.listPrimaryText
                          : _themeConfigService.listSecondaryText,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center, // Center align text
                  ),
                ),
          ),
        ],
      ),
      ),
    );
  }
}