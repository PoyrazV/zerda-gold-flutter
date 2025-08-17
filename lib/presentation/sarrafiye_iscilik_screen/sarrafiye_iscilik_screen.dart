import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/financial_data_service.dart';
import '../../widgets/financial_screen_template.dart';

class SarrafiyeIscilikScreen extends StatefulWidget {
  const SarrafiyeIscilikScreen({Key? key}) : super(key: key);

  @override
  State<SarrafiyeIscilikScreen> createState() => _SarrafiyeIscilikScreenState();
}

class _SarrafiyeIscilikScreenState extends State<SarrafiyeIscilikScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    _refreshController.forward();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sarrafiye işçilikleri güncellendi'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FinancialScreenTemplate(
      title: 'Sarrafiye İşçilikleri',
      currentRoute: '/sarrafiye-iscilik-screen',
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // Table header
            _buildTableHeader(),

            // Sarrafiye işçilik list
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSarrafiyeList(),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      height: 4.h,
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
                fontSize: 4.w,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE8D095), // Gold text
                height: 2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ANKAUF',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 4.w,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE8D095), // Gold text
                height: 2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'VERKAUF',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 4.w,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE8D095), // Gold text
                height: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSarrafiyeList() {
    // Use centralized data service
    final sarrafiyeData = FinancialDataService.getSarrafiyeData();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: sarrafiyeData.length,
      itemBuilder: (context, index) {
        final item = sarrafiyeData[index];
        
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Darker gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return Container(
          height: 8.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.w),
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left section - Asset name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 4.w,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2939),
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Middle section - Buy price
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    CurrencyFormatter.formatExchangeRate(item['buyPrice'] as double),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 4.w,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2939),
                      height: 1.8,
                    ),
                  ),
                ),
              ),
              // Right section - Sell price
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyFormatter.formatExchangeRate(item['sellPrice'] as double),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 4.w,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2939),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}