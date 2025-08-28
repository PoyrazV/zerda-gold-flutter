import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/theme_config_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ticker_section.dart';
import '../../widgets/dashboard_header.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Get watchlist data from service
  List<Map<String, dynamic>> get _watchlistItems => WatchlistService.getWatchlistItems();

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
    
    // Listen to theme changes
    ThemeConfigService().addListener(_onThemeChanged);
  }

  void _updateTicker() {
    print('WatchlistScreen: Watchlist updated. Current items: ${WatchlistService.getWatchlistItems().length}');
    if (mounted) {
      setState(() {});
    }
  }

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

    // Update watchlist data through service
    await WatchlistService.updateWatchlistData();
    setState(() {});

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Takip listesi güncellendi'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeFromWatchlist(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Takip Listesinden Çıkar'),
        content: Text('${item['name']} takip listenizden çıkarılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                WatchlistService.removeFromWatchlist(item['code']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item['name']} takip listesinden çıkarıldı'),
                  backgroundColor: AppTheme.negativeRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.negativeRed),
            child: Text('Çıkar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfigService().primaryColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding and + icon
          DashboardHeader(
            customTopPadding: 3.1.h, // Consistent padding with other pages
            rightWidget: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/asset-selection-screen');
              },
              icon: Icon(
                Icons.add,
                color: Colors.white,
                size: 8.w,
              ),
              padding: EdgeInsets.all(2.w),
            ),
          ),
          
          // Main content with fixed ticker
          Expanded(
            child: Column(
              children: [
                // Horizontal scrollable ticker cards
                const TickerSection(reduceBottomPadding: false),
                
                // Products list - Scrollable
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: const Color(0xFFFFD700),
                    backgroundColor: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.scaffoldBackgroundColor,
                      ),
                      child: _watchlistItems.isEmpty ? _buildEmptyState() : _buildWatchlistContent(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'Takip Listeniz Boş',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Üst kısımdaki + butonuna tıklayarak takip listesine kıymet ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/asset-selection-screen');
              },
              icon: Icon(Icons.add),
              label: Text('Kıymet Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistContent() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _watchlistItems.length,
      itemBuilder: (context, index) {
        final item = _watchlistItems[index];
        final isPositive = item['isPositive'] as bool;
        final changeColor = isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed;
        
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Light gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return Dismissible(
          key: Key(item['code'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.negativeRed,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 5.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Sil',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (direction) {
            final item = _watchlistItems[index];
            WatchlistService.removeFromWatchlist(item['code']);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item['name']} takip listesinden çıkarıldı'),
                backgroundColor: AppTheme.negativeRed,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Geri Al',
                  textColor: Colors.white,
                  onPressed: () {
                    // Re-add to watchlist
                    WatchlistService.addToWatchlist(item);
                  },
                ),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
          child: InkWell(
            onTap: () {
              // Navigate to asset detail screen
              Navigator.pushNamed(
                context,
                '/asset-detail-screen',
                arguments: {
                  'code': item['code'],
                },
              );
            },
            child: Row(
              children: [
                // Asset info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['code'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 4.w,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2939),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        item['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 3.w,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF6B7280),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price info
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatEUR(item['buyPrice'] as double, decimalPlaces: 4),
                        style: GoogleFonts.inter(
                          fontSize: 4.w,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E2939),
                          height: 1.8,
                        ),
                      ),
                      SizedBox(height: 1.5.w),
                      Padding(
                        padding: EdgeInsets.only(top: 1.5.w),
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
                            '%${(item['changePercent'] as double).abs().toStringAsFixed(2).replaceAll('.', ',')}',
                            style: GoogleFonts.inter(
                              fontSize: 2.7.w,
                              fontWeight: FontWeight.w500, // Medium weight
                              color: isPositive 
                                  ? const Color(0xFF047857) // Green text
                                  : const Color(0xFFB91C1C), // Red text
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
          ),
        );
      },
    );
  }


  Widget _buildPriceTicker() {
    // Show watchlist items in ticker
    final tickerData = _watchlistItems.isEmpty 
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
        : _watchlistItems.map((item) => {
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

          final data = tickerData[index];
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
  }


  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/watchlist-screen');
  }}