import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_api_service.dart';
import '../../../services/theme_config_service.dart';
import '../../../services/gold_products_service.dart';
import '../../../widgets/gold_bars_icon.dart';

class AlarmAssetSelectionModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onAssetSelected;

  const AlarmAssetSelectionModal({
    Key? key,
    required this.onAssetSelected,
  }) : super(key: key);

  @override
  State<AlarmAssetSelectionModal> createState() => _AlarmAssetSelectionModalState();
}

class _AlarmAssetSelectionModalState extends State<AlarmAssetSelectionModal>
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchController.addListener(_onSearchChanged);
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    // Fetch both currency and gold data
    await Future.wait([
      _fetchCurrencyData(),
      _fetchGoldData(),
    ]);
  }

  Future<void> _fetchGoldData() async {
    try {
      print('AlarmAssetSelection: Fetching gold data from database...');
      final goldProducts = await GoldProductsService.getProductsWithPrices();
      print('AlarmAssetSelection: Received ${goldProducts.length} gold products from database');
      
      setState(() {
        _allGoldData = goldProducts.map((gold) {
          // Ensure changePercent field exists
          final data = Map<String, dynamic>.from(gold);
          if (!data.containsKey('changePercent')) {
            final buyPrice = (data['buyPrice'] as num?)?.toDouble() ?? 0.0;
            final change = (data['change'] as num?)?.toDouble() ?? 0.0;
            data['changePercent'] = buyPrice > 0 ? (change / buyPrice) * 100 : 0.0;
          }
          return data;
        }).toList();
        _displayedGoldCount = 20; // Reset pagination
        print('AlarmAssetSelection: Successfully loaded ${_allGoldData.length} gold products');
      });
    } catch (e) {
      print('AlarmAssetSelection: Error fetching gold data: $e');
      // Keep empty list on error
      setState(() {
        _allGoldData = [];
      });
    }
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
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('AlarmAssetSelection: Fetching currency data...');
      final apiData = await _currencyApiService.getFormattedCurrencyData();
      print('AlarmAssetSelection: Received ${apiData.length} currencies');
      
      setState(() {
        if (apiData.isNotEmpty) {
          _allCurrencyData = apiData;
          _displayedCurrencyCount = 20; // Reset pagination
          print('AlarmAssetSelection: Currency data loaded successfully');
        } else {
          print('AlarmAssetSelection: API returned empty data, check network');
          _allCurrencyData = []; // Keep empty to show "no data" message
        }
      });
    } catch (e) {
      print('AlarmAssetSelection: Error fetching currency data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

    // Fetch fresh data from both APIs
    await Future.wait([
      _fetchCurrencyData(),
      _fetchGoldData(),
    ]);

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

  void _selectAssetForAlarm(Map<String, dynamic> asset) {
    print('Asset selected: ${asset['code']}');
    // Format asset data for asset detail modal
    final alarmAsset = {
      'code': asset['code'] ?? '',
      'name': asset['name'] ?? '',
      'currentPrice': asset['buyPrice'] ?? 0.0,
      'changePercent': asset['changePercent'] ?? 0.0,
    };
    
    print('Calling onAssetSelected with: $alarmAsset');
    // First call the callback, then pop after a small delay
    widget.onAssetSelected(alarmAsset);
    
    // Pop immediately since parent will handle showing next modal after delay
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: Column(
          children: [
            // Header with ZERDA branding
            _buildHeader(),

            // Search bar (conditionally visible with animation)
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _showSearchBar ? null : 0,
              child: _showSearchBar 
                  ? _buildSearchBar()
                  : Container(),
            ),

            // Tab bar (reduced top spacing)
            Transform.translate(
              offset: Offset(0, _showSearchBar ? 0 : 0.h),
              child: _buildTabBar(),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 8.h,
      decoration: BoxDecoration(
        color: ThemeConfigService().primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.all(2.w),
              ),

              // Title
              Text(
                'Varlık Seçin',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Search icon
              IconButton(
                onPressed: _toggleSearchBar,
                icon: Icon(
                  _showSearchBar ? Icons.search_off : Icons.search,
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
        indicatorColor: ThemeConfigService().secondaryColor,
        labelColor: ThemeConfigService().secondaryColor,
        unselectedLabelColor: Colors.white,
        tabs: [
          Tab(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 0;
                final color = isSelected ? ThemeConfigService().secondaryColor : Colors.white;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.euro,
                      size: 20,
                      color: color,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Döviz',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        fontSize: 14.sp,
                        color: color,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Tab(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == 1;
                final color = isSelected ? ThemeConfigService().secondaryColor : Colors.white;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoldBarsIcon(
                      color: color,
                      size: 20,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Altın',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        fontSize: 14.sp,
                        color: color,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab() {
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
    
    if (currencyData.isEmpty && !_isLoading) {
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
        
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Light gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return Container(
          color: backgroundColor,
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
        
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Light gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

        return Container(
          color: backgroundColor,
          child: _buildAssetRow(gold),
        );
      },
    );
  }

  Widget _buildAssetRow(Map<String, dynamic> asset) {
    final bool isPositive = (asset['isPositive'] as bool? ?? false);

    return InkWell(
      onTap: () {
        _selectAssetForAlarm(asset);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Asset info
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    asset['name'] as String? ?? '',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
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
                    CurrencyFormatter.formatEUR((asset['buyPrice'] as double? ?? 0.0), decimalPlaces: 4),
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

            // Select button
            SizedBox(width: 3.w),
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}