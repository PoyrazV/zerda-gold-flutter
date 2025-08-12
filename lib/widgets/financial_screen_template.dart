import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';
import '../services/watchlist_service.dart';
import 'app_drawer.dart';
import 'bottom_navigation_bar.dart';

class FinancialScreenTemplate extends StatefulWidget {
  final String title;
  final String currentRoute;
  final Widget child;
  final bool showPriceTicker;
  final Future<void> Function()? onRefresh;
  final bool isRefreshing;

  const FinancialScreenTemplate({
    Key? key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.showPriceTicker = true,
    this.onRefresh,
    this.isRefreshing = false,
  }) : super(key: key);

  @override
  State<FinancialScreenTemplate> createState() => _FinancialScreenTemplateState();
}

class _FinancialScreenTemplateState extends State<FinancialScreenTemplate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        color: AppTheme.lightTheme.colorScheme.primary,
        child: Column(
          children: [
            // Header with ZERDA branding
            _buildHeader(),

            // Price ticker (optional)
            if (widget.showPriceTicker) _buildPriceTicker(),

            // Main content
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentRoute: widget.currentRoute),
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

              // Title
              Text(
                widget.title,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                  letterSpacing: 0.5,
                ),
              ),

              // Refresh button or empty space
              widget.onRefresh != null
                  ? IconButton(
                      onPressed: widget.isRefreshing ? null : widget.onRefresh,
                      icon: widget.isRefreshing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                      padding: EdgeInsets.all(2.w),
                    )
                  : SizedBox(width: 48),
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
        ? _getDefaultTickerData()
        : watchlistItems.map((item) => {
            'symbol': item['code'],
            'price': item['buyPrice'],
            'change': item['change'],
            'changePercent': item['changePercent']
          }).toList();

    return Container(
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
            return _buildAddButton();
          }

          final data = tickerData[index];
          final bool isPositive = (data['change'] as double) >= 0;

          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/asset-detail-screen',
                arguments: {'code': data['symbol'] as String},
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
                            '₺${(data['price'] as double).toStringAsFixed(4)}',
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
  }

  Widget _buildAddButton() {
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

  List<Map<String, dynamic>> _getDefaultTickerData() {
    return [
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
    ];
  }
}