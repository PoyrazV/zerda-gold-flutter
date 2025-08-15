import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  
  // All currency data from API
  List<Map<String, dynamic>> _allCurrencyData = [];
  
  // Featured currencies for top cards
  List<Map<String, dynamic>> _featuredCurrencies = [];

  // Currency data for the products list - show all currencies
  List<Map<String, dynamic>> get _currencyData => _allCurrencyData;

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
          // Select featured currencies (USD, GBP, TRY, CHF, JPY)
          _featuredCurrencies = [
            ...currencies.where((c) => 
              c['code'] == 'USD/EUR' || 
              c['code'] == 'TRY/EUR' || 
              c['code'] == 'GBP/EUR' ||
              c['code'] == 'CHF/EUR' ||
              c['code'] == 'JPY/EUR'
            ).take(5),
          ];
        });
      }
    } catch (e) {
      print('Error loading currency data: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18214F),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Modern Mobile-First Header
          _buildMobileHeader(),
          
          // Main content with fixed ticker and header
          Expanded(
            child: Column(
              children: [
                // Horizontal scrollable ticker cards - Fixed at top
                _buildTickerSection(),
                
                // Table header - Fixed below ticker
                _buildTableHeader(),
                
                // Products list with alternating colors - Scrollable
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: const Color(0xFFFFD700), //Ticker arkaplan rengi
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _buildProductsList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }


  Widget _buildMobileHeader() {
    return Container(
      height: 13.h, // 12-14% of screen height
      decoration: const BoxDecoration(
        color: Color(0xFF18214F), // Dark navy background
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              // Hamburger menu icon
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 6.w, // Responsive size
                ),
              ),
              
              // ZERDA GOLD logo - responsive SVG
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/zerda-gold-logo.svg',
                    height: 8.h, // Increased height for better visibility
                    width: 40.w, // Increased width constraint
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => SizedBox(
                      height: 8.h,
                      width: 40.w,
                    ),
                  ),
                ),
              ),
              
              // Right side - placeholder for future notification icon
              SizedBox(width: 12.w),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTickerSection() {
    return Container(
      height: 24.w, // Adjusted height with some margin for cards
      margin: EdgeInsets.only(top: 0.w, bottom: 3.w),
      child: _featuredCurrencies.isEmpty 
        ? Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFFFD700),
            ),
          )
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemCount: _featuredCurrencies.length,
            itemBuilder: (context, index) {
              final currency = _featuredCurrencies[index];
              return _buildTickerCard(currency);
            },
          ),
    );
  }

  Widget _buildTickerCard(Map<String, dynamic> currency) {
    final bool isPositive = currency['isPositive'] as bool;
    final double change = currency['change'] as double;
    
    return Container(
      width: 23.w, // Further increased width for larger text
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
                currency['name'] as String,
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
                CurrencyFormatter.formatExchangeRate(currency['buyPrice'] as double),
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
                      ? const Color(0xFFECFDF5) // Green background for increase
                      : const Color(0xFFFEF2F2), // Red background for decrease
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPositive 
                        ? const Color(0x33059669) // Fixed green border with opacity
                        : const Color(0x1ADC2626), // Red border with opacity
                    width: 1,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(2).replaceAll('.', ',')}%',
                    style: GoogleFonts.inter(
                      fontSize: 2.5.w, // Increased font size for better readability
                      fontWeight: FontWeight.w900, // Extra bold
                      color: isPositive 
                          ? const Color(0xFF047857) // Green text
                          : const Color(0xFFB91C1C), // Red text
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center, // Center align text
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      height: 4.h, // 5-6% of screen height
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A), // Updated background color
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'PRODUKT',
              style: GoogleFonts.inter(
                fontSize: 4.w, // 1rem equivalent - responsive
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFFFFF), // White text
                height: 2, // Line height 2.5rem
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Text(
                'ANKAUF',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 4.w, // 1rem equivalent - responsive
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFFFFF), // White text
                  height: 2, // Line height 2.5rem
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'VERKAUF',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 4.w, // 1rem equivalent - responsive
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFFFFF), // White text
                height: 2, // Line height 2.5rem
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductsList() {
    if (_currencyData.isEmpty) {
      return Container(
        height: 20.h,
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFFFD700),
          ),
        ),
      );
    }
    
    return Column(
      children: _currencyData.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> currency = entry.value;
        return _buildProductRow(currency, index);
      }).toList(),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> currency, int index) {
    final bool isPositive = currency['isPositive'] as bool;
    final double change = currency['change'] as double;
    final String currentTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    
    // Alternating row colors
    final Color backgroundColor = index.isEven 
        ? const Color(0xFFF6F6F6) // Gray for even rows
        : const Color(0xFFFFFFFF); // White for odd rows
    
    return Container(
      height: 6.5.h, // Reduced from 8.h to 6.h for more compact rows
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.w),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Column(
        children: [
          // Top row with currency name and prices
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  currency['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 4.w, // 0.875rem equivalent - responsive
                    fontWeight: FontWeight.w500, // Medium weight
                    color: const Color(0xFF1E2939),
                    height: 1.8, // Line height 1.8rem
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Text(
                    CurrencyFormatter.formatExchangeRate(currency['buyPrice'] as double),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 4.w, // 1rem equivalent - responsive
                      fontWeight: FontWeight.w900, // Black weight
                      color: const Color(0xFF1E2939),
                      height: 1.8,
                  ),
                ),
              ),
            ),  
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Text(
                    CurrencyFormatter.formatExchangeRate(currency['sellPrice'] as double),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 4.w, // 1rem equivalent - responsive
                      fontWeight: FontWeight.w900, // Black weight
                      color: const Color(0xFF1E2939),
                      height: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.w),
          // Bottom row with time and percentage change
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Time on the left
              Text(
                currentTime,
                style: GoogleFonts.inter(
                  fontSize: 2.5.w, // Back to original font size
                  fontWeight: FontWeight.normal, // Regular weight
                  color: const Color(0xFF131313),
                  height: 1.5,
                ),
              ),
              SizedBox(width: 2.w), // Space between time and percentage
              // Percentage change container on the right
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                decoration: BoxDecoration(
                  color: isPositive 
                      ? const Color(0xFFECFDF5) // Green background for increase
                      : const Color(0xFFFEF2F2), // Red background for decrease
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPositive 
                        ? const Color(0x3305966) // Green border with opacity
                        : const Color(0x1ADC2626), // Red border with opacity
                    width: 1,
                  ),
                ),
                child: Text(
                  '%${change.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.inter(
                    fontSize: 2.5.w, // 0.625rem equivalent - responsive
                    fontWeight: FontWeight.w900, // Extra bold for percentage numbers
                    color: isPositive 
                        ? const Color(0xFF047857) // Green text
                        : const Color(0xFFB91C1C), // Red text
                    height: 1.0, // Line height 0.625rem
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/dashboard-screen');
  }


  // Removed _formatPrice method - now using CurrencyFormatter.formatExchangeRate


}
