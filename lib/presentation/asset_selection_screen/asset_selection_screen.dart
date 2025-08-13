import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
import '../../widgets/bottom_navigation_bar.dart';

class AssetSelectionScreen extends StatefulWidget {
  const AssetSelectionScreen({Key? key}) : super(key: key);

  @override
  State<AssetSelectionScreen> createState() => _AssetSelectionScreenState();
}

class _AssetSelectionScreenState extends State<AssetSelectionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _refreshController;
  bool _isRefreshing = false;
  
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  List<Map<String, dynamic>> _currencyData = [];
  List<Map<String, dynamic>> _goldData = [];
  List<Map<String, dynamic>> _filteredCurrencyData = [];
  List<Map<String, dynamic>> _filteredGoldData = [];
  
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // Gold data - keeping static since API might not have gold prices
  final List<Map<String, dynamic>> _staticGoldData = [
    {
      'code': 'GRAM',
      'name': 'Gram Altın',
      'buyPrice': 2640.50,
      'sellPrice': 2654.30,
      'change': 0.65,
      'changePercent': 0.025,
      'isPositive': true,
    },
    {
      'code': 'YÇEYREK',
      'name': 'Yeni Çeyrek Altın',
      'buyPrice': 2876.50,
      'sellPrice': 2891.75,
      'change': 0.85,
      'changePercent': 0.030,
      'isPositive': true,
    },
    {
      'code': 'EÇEYREK',
      'name': 'Eski Çeyrek Altın',
      'buyPrice': 2845.25,
      'sellPrice': 2860.40,
      'change': -0.45,
      'changePercent': -0.016,
      'isPositive': false,
    },
    {
      'code': 'YYARIM',
      'name': 'Yeni Yarım Altın',
      'buyPrice': 5753.00,
      'sellPrice': 5783.50,
      'change': 1.12,
      'changePercent': 0.019,
      'isPositive': true,
    },
    {
      'code': 'EYARIM',
      'name': 'Eski Yarım Altın',
      'buyPrice': 5690.75,
      'sellPrice': 5720.80,
      'change': -0.28,
      'changePercent': -0.005,
      'isPositive': false,
    },
    {
      'code': 'YTAM',
      'name': 'Yeni Tam Altın',
      'buyPrice': 11506.00,
      'sellPrice': 11567.00,
      'change': 0.95,
      'changePercent': 0.008,
      'isPositive': true,
    },
    {
      'code': 'ETAM',
      'name': 'Eski Tam Altın',
      'buyPrice': 11381.50,
      'sellPrice': 11441.60,
      'change': -0.62,
      'changePercent': -0.005,
      'isPositive': false,
    },
    {
      'code': 'CUMHUR',
      'name': 'Cumhuriyet Altını',
      'buyPrice': 11548.90,
      'sellPrice': 11610.30,
      'change': 0.78,
      'changePercent': 0.007,
      'isPositive': true,
    },
    {
      'code': 'GUMUS',
      'name': 'Gümüş (Gram)',
      'buyPrice': 33.45,
      'sellPrice': 34.25,
      'change': -0.45,
      'changePercent': -0.013,
      'isPositive': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _goldData = List.from(_staticGoldData);
    _filteredGoldData = List.from(_goldData);
    _searchController.addListener(_onSearchChanged);
    _fetchCurrencyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrencyData() async {
    print('AssetSelection: Starting to fetch currency data...');
    try {
      setState(() {
        _isLoading = true;
        print('AssetSelection: Set loading state to true');
      });
      
      print('AssetSelection: Fetching currency data from API...');
      final apiData = await _currencyApiService.getFormattedCurrencyData();
      print('AssetSelection: Received ${apiData.length} currencies from API');
      print('AssetSelection: First few currencies: ${apiData.take(3).toList()}');
      
      setState(() {
        if (apiData.isNotEmpty) {
          _currencyData = apiData;
          _filteredCurrencyData = List.from(_currencyData);
          print('AssetSelection: Successfully loaded ${_currencyData.length} currencies');
          print('AssetSelection: Filtered data length: ${_filteredCurrencyData.length}');
        } else {
          print('AssetSelection: API returned empty data');
        }
      });
    } catch (e) {
      print('AssetSelection: Error fetching currency data: $e');
      print('AssetSelection: Stack trace: ${StackTrace.current}');
      // Keep empty lists on error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          print('AssetSelection: Set loading state to false. Currency data length: ${_currencyData.length}');
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencyData = List.from(_currencyData);
        _filteredGoldData = List.from(_goldData);
      } else {
        _filteredCurrencyData = _currencyData.where((currency) {
          final code = (currency['code'] as String).toLowerCase();
          final name = (currency['name'] as String).toLowerCase();
          return code.contains(query) || name.contains(query);
        }).toList();
        
        _filteredGoldData = _goldData.where((gold) {
          final code = (gold['code'] as String).toLowerCase();
          final name = (gold['name'] as String).toLowerCase();
          return code.contains(query) || name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    _refreshController.forward();

    // Fetch fresh data from API
    await _fetchCurrencyData();

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kıymetler güncellendi'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addToWatchlist(Map<String, dynamic> asset) {
    print('AssetSelection: Adding to watchlist: $asset');
    
    // Ensure the asset has all required fields for WatchlistService
    final watchlistAsset = {
      'code': asset['code'] ?? '',
      'name': asset['name'] ?? '',
      'buyPrice': asset['buyPrice'] ?? 0.0,
      'sellPrice': asset['sellPrice'] ?? (asset['buyPrice'] ?? 0.0) + 0.01,
      'change': asset['change'] ?? 0.0,
      'changePercent': asset['change'] ?? 0.0, // API has 'change' field, not 'changePercent'
      'isPositive': asset['isPositive'] ?? true,
    };
    
    print('AssetSelection: Formatted watchlist asset: $watchlistAsset');
    
    WatchlistService.addToWatchlist(watchlistAsset);
    
    print('AssetSelection: Current watchlist items: ${WatchlistService.getWatchlistItems().length}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${asset['name']} eklendi',
          style: TextStyle(fontSize: 12.sp),
        ),
        backgroundColor: AppTheme.positiveGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: 4.w,
          right: 4.w,
        ),
      ),
    );
    
    // Trigger rebuild to update the UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: Column(
          children: [
            // Header with ZERDA branding
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Tab bar
            _buildTabBar(),

            // Main content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCurrencyTab(),
                      _buildGoldTab(),
                    ],
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
              // Back button
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.all(2.w),
              ),

              // Title
              Text(
                'Kıymet Ekle',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space for symmetry
              SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kıymet ara...',
                hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: Icon(
                Icons.clear,
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Döviz',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Altın',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab() {
    print('AssetSelection _buildCurrencyTab: Loading: $_isLoading, FilteredData: ${_filteredCurrencyData.length}');
    
    if (_filteredCurrencyData.isEmpty && !_isLoading) {
      print('AssetSelection: Showing empty state');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'Kıymet bulunamadı',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'API\'dan veri çekilemiyor olabilir',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _filteredCurrencyData.length,
      itemBuilder: (context, index) {
        final currency = _filteredCurrencyData[index];
        final isLastItem = index == _filteredCurrencyData.length - 1;

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
          child: _buildAssetRow(currency),
        );
      },
    );
  }

  Widget _buildGoldTab() {
    if (_filteredGoldData.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'Aradığınız altın kıymeti bulunamadı',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _filteredGoldData.length,
      itemBuilder: (context, index) {
        final gold = _filteredGoldData[index];
        final isLastItem = index == _filteredGoldData.length - 1;

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
          child: _buildAssetRow(gold),
        );
      },
    );
  }

  Widget _buildAssetRow(Map<String, dynamic> asset) {
    final bool isPositive = (asset['isPositive'] as bool? ?? false);
    final bool isInWatchlist = WatchlistService.isInWatchlist(asset['code'] as String? ?? '');

    return InkWell(
      onTap: () {
        if (!isInWatchlist) {
          _addToWatchlist(asset);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Zaten eklendi',
                style: TextStyle(fontSize: 12.sp),
              ),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
              margin: EdgeInsets.only(
                bottom: 12.h,
                left: 4.w,
                right: 4.w,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 1.5.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Asset info
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    asset['code'] as String? ?? '',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.2.h),
                  Text(
                    asset['name'] as String? ?? '',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Price and change
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.formatTRY((asset['buyPrice'] as double? ?? 0.0), decimalPlaces: 4),
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.2.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
                        size: 12,
                      ),
                      SizedBox(width: 0.5.w),
                      Text(
                        CurrencyFormatter.formatPercentageChange((asset['changePercent'] as double? ?? 0.0)),
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: isPositive ? AppTheme.positiveGreen : AppTheme.negativeRed,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Add button or added indicator
            SizedBox(width: 3.w),
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: isInWatchlist 
                    ? AppTheme.positiveGreen 
                    : AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInWatchlist ? Icons.check : Icons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/asset-selection-screen');
  }
}