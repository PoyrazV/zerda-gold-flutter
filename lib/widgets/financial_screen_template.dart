import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';
import '../services/watchlist_service.dart';
import 'app_drawer.dart';
import 'bottom_navigation_bar.dart';
import 'price_ticker.dart';

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

            // Price ticker (optional) - now using API data
            if (widget.showPriceTicker) const PriceTicker(),

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
        color: const Color(0xFF18214F),
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

}