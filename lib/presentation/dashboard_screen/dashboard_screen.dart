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
import '../../widgets/dashboard_header.dart';
import '../../widgets/ticker_section.dart';


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
          // Modern Mobile-First Header with reduced bottom spacing
          Container(
            height: 13.h,
            decoration: const BoxDecoration(
              color: Color(0xFF18214F),
            ),
            child: SafeArea(
              top: true,
              child: Padding(
                padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 0.5.h), // Aligned with DashboardHeader widget
                child: Row(
                  children: [
                    Builder(
                      builder: (BuildContext context) {
                        return IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 8.w,
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/zerda-gold-logo.svg',
                          height: 5.h,
                          width: 25.w,
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => SizedBox(
                            height: 5.h,
                            width: 25.w,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content with fixed ticker and header
          Expanded(
            child: Column(
              children: [
                // Horizontal scrollable ticker cards - Fixed at top
                const TickerSection(reduceBottomPadding: true),
                
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


  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/dashboard-screen');
  }



  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      height: 4.h, // 5-6% of screen height
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: const BoxDecoration(
        color: Color(0xFF18214F), // Dark navy background
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
                color: const Color(0xFFE8D095), // Gold text
                height: 2, // Line height 2.5rem
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ANKAUF',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 4.w, // 1rem equivalent - responsive
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE8D095), // Gold text
                height: 2, // Line height 2.5rem
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
                color: const Color(0xFFE8D095), // Gold text
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
        ? const Color(0xFFF0F0F0) // Darker gray for even rows
        : const Color(0xFFFFFFFF); // White for odd rows
    
    return Container(
      height: 8.h, // Reduced from 8.h to 6.h for more compact rows
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.w),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left section - Currency name and time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 0.5.w),
                Padding(
                  padding: EdgeInsets.only(top: 1.w),
                  child: Text(
                    currency['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 4.w, // 0.875rem equivalent - responsive
                    fontWeight: FontWeight.w800, // Bold weight for name
                    color: const Color(0xFF1E2939),
                    height: 1.4, // Reduced line height for compact layout
                  ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 2.w),
                Padding(
                  padding: EdgeInsets.only(top: 2.w),
                  child: Text(
                    currentTime,
                    style: GoogleFonts.inter(
                      fontSize: 3.w, // Smaller font size for time
                      fontWeight: FontWeight.normal, // Regular weight
                      color: const Color(0xFF6B7280), // Lighter gray color
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Middle section - Buy price
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(top: 1.w),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  CurrencyFormatter.formatExchangeRate(currency['buyPrice'] as double),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 4.w, // 1rem equivalent - responsive
                    fontWeight: FontWeight.w700, // Semi-bold weight
                    color: const Color(0xFF1E2939),
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),
          // Right section - Sell price and percentage change
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1.w),
                  child: Text(
                    CurrencyFormatter.formatExchangeRate(currency['sellPrice'] as double),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 4.w, // 1rem equivalent - responsive
                      fontWeight: FontWeight.w700, // Semi-bold weight
                      color: const Color(0xFF1E2939),
                      height: 1.6,
                    ),
                  ),
                ),
                SizedBox(height: 1.5.w),
                Padding(
                  padding: EdgeInsets.only(top: 1.5.w, right: 1.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.w),
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
                  child: Text(
                    '%${change.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                      fontSize: 2.7.w, // Increased font size
                      fontWeight: FontWeight.w500, // Medium weight instead of extra bold
                      color: isPositive 
                          ? const Color(0xFF047857) // Green text
                          : const Color(0xFFB91C1C), // Red text
                      height: 1.0, // Line height 0.625rem
                    ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
  


  // Removed _formatPrice method - now using CurrencyFormatter.formatExchangeRate


}
