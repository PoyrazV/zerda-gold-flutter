
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_export.dart';
import '../services/currency_api_service.dart';

class TickerSection extends StatefulWidget {
  final bool reduceBottomPadding;
  
  const TickerSection({Key? key, this.reduceBottomPadding = false}) : super(key: key);

  @override
  State<TickerSection> createState() => _TickerSectionState();
}

class _TickerSectionState extends State<TickerSection> {
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  List<Map<String, dynamic>> _featuredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrencyData();
  }

  Future<void> _loadCurrencyData() async {
    try {
      final currencies = await _currencyApiService.getFormattedCurrencyData();
      if (mounted) {
        setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27.w, // Reduced height to decrease spacing
      decoration: const BoxDecoration(
        color: Color(0xFF18214F), // Dark navy background for ticker section
      ),
      padding: EdgeInsets.only(bottom: widget.reduceBottomPadding ? 0.5.w : 2.w), // Conditional bottom padding
      child: _featuredCurrencies.isEmpty 
        ? Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFFFD700),
            ),
          )
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemCount: _featuredCurrencies.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == _featuredCurrencies.length) {
                return _buildAddTickerCard();
              }
              final currency = _featuredCurrencies[index];
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
    final bool isPositive = currency['isPositive'] as bool;
    final double change = currency['change'] as double;
    
    return Container(
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
                    '%${change.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                      fontSize: 2.7.w, // Increased font size to match list
                      fontWeight: FontWeight.w500, // Medium weight to match list
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
}