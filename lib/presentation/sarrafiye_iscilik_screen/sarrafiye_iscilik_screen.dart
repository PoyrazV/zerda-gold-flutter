import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Birim',
              textAlign: TextAlign.left,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Alış',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 6.5.w),
              child: Text(
                'Satış',
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
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
        final isLastItem = index == sarrafiyeData.length - 1;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            border: isLastItem ? null : Border(
              bottom: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 1.6.h, horizontal: 0.w),
            child: Row(
              children: [
                // Name
                Expanded(
                  flex: 3,
                  child: Text(
                    item['name'] as String,
                    style: AppTheme.dataTextStyle(
                      isLight: true,
                      fontSize: 12.sp,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                // Buy price
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.formatNumber(item['buyPrice'] as double, decimalPlaces: 4),
                    textAlign: TextAlign.center,
                    style: AppTheme.dataTextStyle(
                      isLight: true,
                      fontSize: 12.sp,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                // Sell price
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 4.w),
                    child: Text(
                      CurrencyFormatter.formatNumber(item['sellPrice'] as double, decimalPlaces: 4),
                      style: AppTheme.dataTextStyle(
                        isLight: true,
                        fontSize: 12.sp,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}