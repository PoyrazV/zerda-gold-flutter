import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../services/currency_api_service.dart';
import '../../services/theme_config_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/gold_bars_icon.dart';

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
  
  // All data from API
  List<Map<String, dynamic>> _allCurrencyData = [];
  List<Map<String, dynamic>> _allGoldData = [];
  
  // Pagination variables
  int _displayedCurrencyCount = 20;
  int _displayedGoldCount = 20;
  bool _isLoadingMoreCurrencies = false;
  bool _isLoadingMoreGold = false;
  
  // Search and filtered data
  List<Map<String, dynamic>> _filteredCurrencyData = [];
  List<Map<String, dynamic>> _filteredGoldData = [];
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showSearchBar = false;

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _allGoldData = List.from(_staticGoldData);
    _filteredGoldData = List.from(_allGoldData);
    _searchController.addListener(_onSearchChanged);
    _fetchCurrencyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
          _allCurrencyData = apiData;
          _displayedCurrencyCount = 20; // Reset pagination
          print('AssetSelection: Successfully loaded ${_allCurrencyData.length} currencies');
          print('AssetSelection: Will display first ${_displayedCurrencyCount} currencies');
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
          print('AssetSelection: Set loading state to false. Currency data length: ${_allCurrencyData.length}');
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      
      if (query.isEmpty) {
        _filteredCurrencyData = [];
        _filteredGoldData = [];
      } else {
        _filteredCurrencyData = _allCurrencyData.where((currency) {
          final code = (currency['code'] as String).toLowerCase();
          final name = (currency['name'] as String).toLowerCase();
          return code.contains(query) || name.contains(query);
        }).toList();
        
        _filteredGoldData = _allGoldData.where((gold) {
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

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      
      if (_showSearchBar) {
        // Auto-focus search field when showing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        // Clear search when hiding search bar
        _searchController.clear();
        _isSearching = false;
        _filteredCurrencyData = [];
        _filteredGoldData = [];
        // Remove focus
        _searchFocusNode.unfocus();
      }
    });
  }

  void _loadMoreCurrencies() {
    if (_isLoadingMoreCurrencies) return;
    
    setState(() {
      _isLoadingMoreCurrencies = true;
    });
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _displayedCurrencyCount = (_displayedCurrencyCount + 20).clamp(0, _allCurrencyData.length);
          _isLoadingMoreCurrencies = false;
        });
      }
    });
  }

  void _loadMoreGold() {
    if (_isLoadingMoreGold) return;
    
    setState(() {
      _isLoadingMoreGold = true;
    });
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _displayedGoldCount = (_displayedGoldCount + 20).clamp(0, _allGoldData.length);
          _isLoadingMoreGold = false;
        });
      }
    });
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

            // Tab bar
            _buildTabBar(),

            // Search bar (conditionally visible with animation - below tabs)
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _showSearchBar ? null : 0,
              child: _showSearchBar 
                  ? _buildSearchBar()
                  : SizedBox.shrink(),
            ),

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
        color: ThemeConfigService().primaryColor,
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
                'Varlık Ekle',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Search icon
              IconButton(
                onPressed: _toggleSearchBar,
                icon: Icon(
                  _showSearchBar ? Icons.close : Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.all(2.w),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
              focusNode: _searchFocusNode,
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
      color: ThemeConfigService().primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: ThemeConfigService().secondaryColor, // Dynamic secondary color
        indicatorWeight: 3,
        labelColor: ThemeConfigService().secondaryColor, // Dynamic secondary color for selected
        unselectedLabelColor: Colors.grey, // Gray for unselected
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.euro,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Döviz',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoldBarsIcon(
                  size: 16,
                  color: _tabController.index == 1 ? ThemeConfigService().secondaryColor : Colors.grey,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Altın',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
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
    print('AssetSelection _buildCurrencyTab: Loading: $_isLoading, IsSearching: $_isSearching');
    
    // Determine which data to show
    final List<Map<String, dynamic>> currencyData;
    final bool hasMoreToLoad;
    
    if (_isSearching) {
      currencyData = _filteredCurrencyData;
      hasMoreToLoad = false; // No pagination during search
    } else {
      currencyData = _allCurrencyData.take(_displayedCurrencyCount).toList();
      hasMoreToLoad = _displayedCurrencyCount < _allCurrencyData.length;
    }
    
    print('AssetSelection: Showing ${currencyData.length} currencies, HasMore: $hasMoreToLoad');
    
    if (currencyData.isEmpty && !_isLoading) {
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
              _isSearching ? 'Kıymet bulunamadı' : 'Veri yükleniyor...',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (!_isSearching) ...[
              SizedBox(height: 1.h),
              Text(
                'API\'dan veri çekilemiyor olabilir',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: currencyData.length + (hasMoreToLoad ? 1 : 0),
      itemBuilder: (context, index) {
        // Load More button
        if (index == currencyData.length && hasMoreToLoad) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: ElevatedButton(
              onPressed: _isLoadingMoreCurrencies ? null : _loadMoreCurrencies,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoadingMoreCurrencies
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 2.w),
                        Text(
                          'Daha Fazla Göster',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          );
        }

        final currency = currencyData[index];
        
        // Alternating row colors like Dashboard
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Darker gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return Container(
          height: 8.h,
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: _buildAssetRow(currency),
        );
      },
    );
  }

  Widget _buildGoldTab() {
    // Determine which data to show
    final List<Map<String, dynamic>> goldData;
    final bool hasMoreToLoad;
    
    if (_isSearching) {
      goldData = _filteredGoldData;
      hasMoreToLoad = false; // No pagination during search
    } else {
      goldData = _allGoldData.take(_displayedGoldCount).toList();
      hasMoreToLoad = _displayedGoldCount < _allGoldData.length;
    }

    if (goldData.isEmpty && !_isLoading) {
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
              _isSearching ? 'Aradığınız altın kıymeti bulunamadı' : 'Altın verileri yükleniyor...',
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
      itemCount: goldData.length + (hasMoreToLoad ? 1 : 0),
      itemBuilder: (context, index) {
        // Load More button
        if (index == goldData.length && hasMoreToLoad) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: ElevatedButton(
              onPressed: _isLoadingMoreGold ? null : _loadMoreGold,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoadingMoreGold
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 2.w),
                        Text(
                          'Daha Fazla Göster',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          );
        }

        final gold = goldData[index];
        
        // Alternating row colors like Dashboard
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Darker gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return Container(
          height: 8.h,
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: _buildAssetRow(gold),
        );
      },
    );
  }

  Widget _buildAssetRow(Map<String, dynamic> asset) {
    final bool isPositive = (asset['isPositive'] as bool? ?? false);
    final bool isInWatchlist = WatchlistService.isInWatchlist(asset['code'] as String? ?? '');
    final double changePercent = asset['changePercent'] as double? ?? 0.0;

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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Asset name only
            Expanded(
              flex: 4,
              child: Text(
                asset['name'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: 4.w,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2939),
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Price and percentage
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    CurrencyFormatter.formatEUR((asset['buyPrice'] as double? ?? 0.0), decimalPlaces: 4),
                    style: GoogleFonts.inter(
                      fontSize: 4.w,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2939),
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 0.3.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                    decoration: BoxDecoration(
                      color: isPositive 
                          ? const Color(0xFFECFDF5) // Green background for increase
                          : const Color(0xFFFEF2F2), // Red background for decrease
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isPositive 
                            ? const Color(0x33059669) // Green border with opacity
                            : const Color(0x1ADC2626), // Red border with opacity
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '%${changePercent.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.inter(
                        fontSize: 2.8.w,
                        fontWeight: FontWeight.w600,
                        color: isPositive 
                            ? const Color(0xFF059669) // Green text
                            : const Color(0xFFDC2626), // Red text
                        height: 1.2,
                      ),
                    ),
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