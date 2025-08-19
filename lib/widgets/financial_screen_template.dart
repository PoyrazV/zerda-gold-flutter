import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';
import '../services/watchlist_service.dart';
import 'app_drawer.dart';
import 'bottom_navigation_bar.dart';
import 'ticker_section.dart';
import 'dashboard_header.dart';

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
            const DashboardHeader(),

            // Price ticker (optional) - now using API data
            if (widget.showPriceTicker) const TickerSection(reduceBottomPadding: false),

            // Main content
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentRoute: widget.currentRoute),
    );
  }


}