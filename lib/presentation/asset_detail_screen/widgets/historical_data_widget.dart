import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class HistoricalDataWidget extends StatefulWidget {
  final String assetSymbol;

  const HistoricalDataWidget({
    Key? key,
    required this.assetSymbol,
  }) : super(key: key);

  @override
  State<HistoricalDataWidget> createState() => _HistoricalDataWidgetState();
}

class _HistoricalDataWidgetState extends State<HistoricalDataWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> historicalData = [
    {
      "date": "05.08.2025",
      "open": "34.2850",
      "high": "34.3520",
      "low": "34.1980",
      "close": "34.2850",
      "change": "+0.15",
      "changePercent": "+0.44%",
      "isPositive": true,
    },
    {
      "date": "04.08.2025",
      "open": "34.1350",
      "high": "34.2100",
      "low": "34.0850",
      "close": "34.1350",
      "change": "-0.08",
      "changePercent": "-0.23%",
      "isPositive": false,
    },
    {
      "date": "03.08.2025",
      "open": "34.2150",
      "high": "34.2850",
      "low": "34.1200",
      "close": "34.2150",
      "change": "+0.12",
      "changePercent": "+0.35%",
      "isPositive": true,
    },
    {
      "date": "02.08.2025",
      "open": "34.0950",
      "high": "34.1850",
      "low": "34.0200",
      "close": "34.0950",
      "change": "-0.05",
      "changePercent": "-0.15%",
      "isPositive": false,
    },
    {
      "date": "01.08.2025",
      "open": "34.1450",
      "high": "34.2200",
      "low": "34.0850",
      "close": "34.1450",
      "change": "+0.18",
      "changePercent": "+0.53%",
      "isPositive": true,
    },
    {
      "date": "31.07.2025",
      "open": "33.9650",
      "high": "34.0850",
      "low": "33.9200",
      "close": "33.9650",
      "change": "-0.12",
      "changePercent": "-0.35%",
      "isPositive": false,
    },
    {
      "date": "30.07.2025",
      "open": "34.0850",
      "high": "34.1550",
      "low": "33.9850",
      "close": "34.0850",
      "change": "+0.09",
      "changePercent": "+0.26%",
      "isPositive": true,
    },
    {
      "date": "29.07.2025",
      "open": "33.9950",
      "high": "34.0650",
      "low": "33.9200",
      "close": "33.9950",
      "change": "-0.03",
      "changePercent": "-0.09%",
      "isPositive": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate loading more data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'Geçmiş Veriler',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          _buildTableHeader(),
          Container(
            height: 40.h,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: historicalData.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == historicalData.length) {
                  return _buildLoadingIndicator();
                }
                return _buildDataRow(historicalData[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Tarih',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Açılış',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Yüksek',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Düşük',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Kapanış',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Değişim',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> data, int index) {
    final bool isPositive = data["isPositive"] as bool;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? AppTheme.lightTheme.colorScheme.surface
            : AppTheme.lightTheme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerLight.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              data["date"] as String,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              data["open"] as String,
              style: AppTheme.dataTextStyle(
                isLight: true,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              data["high"] as String,
              style: AppTheme.dataTextStyle(
                isLight: true,
                fontSize: 12,
              ).copyWith(
                color: AppTheme.positiveGreen,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              data["low"] as String,
              style: AppTheme.dataTextStyle(
                isLight: true,
                fontSize: 12,
              ).copyWith(
                color: AppTheme.negativeRed,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              data["close"] as String,
              style: AppTheme.dataTextStyle(
                isLight: true,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName:
                      isPositive ? 'keyboard_arrow_up' : 'keyboard_arrow_down',
                  color: isPositive
                      ? AppTheme.positiveGreen
                      : AppTheme.negativeRed,
                  size: 12,
                ),
                SizedBox(width: 1.w),
                Flexible(
                  child: Text(
                    data["changePercent"] as String,
                    style: AppTheme.priceChangeTextStyle(
                      isLight: true,
                      isPositive: isPositive,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
