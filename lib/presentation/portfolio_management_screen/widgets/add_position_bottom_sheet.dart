import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_api_service.dart';
import '../../../widgets/gold_bars_icon.dart';

class AddPositionBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddPosition;

  const AddPositionBottomSheet({
    Key? key,
    required this.onAddPosition,
  }) : super(key: key);

  @override
  State<AddPositionBottomSheet> createState() => _AddPositionBottomSheetState();
}

class _AddPositionBottomSheetState extends State<AddPositionBottomSheet>
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
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _allGoldData = List.from(_staticGoldData);
    _filteredGoldData = List.from(_allGoldData);
    print('AddPositionBottomSheet: Gold data initialized with ${_allGoldData.length} items');
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
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('AddPositionBottomSheet: Fetching currency data...');
      final apiData = await _currencyApiService.getFormattedCurrencyData();
      print('AddPositionBottomSheet: Received ${apiData.length} currencies');
      
      setState(() {
        if (apiData.isNotEmpty) {
          _allCurrencyData = apiData;
          _displayedCurrencyCount = 20; // Reset pagination
          print('AddPositionBottomSheet: Currency data loaded successfully');
        } else {
          print('AddPositionBottomSheet: API returned empty data, check network');
          _allCurrencyData = []; // Keep empty to show "no data" message
        }
      });
    } catch (e) {
      print('AddPositionBottomSheet: Error fetching currency data: $e');
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

  void _selectAssetForPortfolio(Map<String, dynamic> asset) {
    print('Asset selected for portfolio: ${asset['code']}');
    // Show a second modal for entering position details
    Navigator.pop(context); // Close current modal
    _showPositionDetailsModal(asset);
  }

  void _showPositionDetailsModal(Map<String, dynamic> asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PositionDetailsDialog(
        asset: asset,
        onAddPosition: widget.onAddPosition,
      ),
    );
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
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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
                hintText: 'Varlık ara...',
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
                GoldBarsIcon(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
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
              _isSearching ? 'Varlık bulunamadı' : 'Veri yükleniyor...',
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
        final isLastItem = index == currencyData.length - 1 && !hasMoreToLoad;

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
              _isSearching ? 'Aradığınız altın varlığı bulunamadı' : 'Altın verileri yükleniyor...',
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
        final isLastItem = index == goldData.length - 1 && !hasMoreToLoad;

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

    return InkWell(
      onTap: () {
        _selectAssetForPortfolio(asset);
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
                Icons.add,
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

// Position Details Dialog for entering quantity and price
class _PositionDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> asset;
  final Function(Map<String, dynamic>) onAddPosition;

  const _PositionDetailsDialog({
    Key? key,
    required this.asset,
    required this.onAddPosition,
  }) : super(key: key);

  @override
  State<_PositionDetailsDialog> createState() => _PositionDetailsDialogState();
}

class _PositionDetailsDialogState extends State<_PositionDetailsDialog> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  double _quantity = 0.0;
  double _price = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current price if available
    final currentPrice = widget.asset['buyPrice'] as double? ?? 0.0;
    if (currentPrice > 0) {
      _price = currentPrice;
      _priceController.text = '₺${currentPrice.toStringAsFixed(2)}';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool _canAddPosition() {
    return _quantity > 0 && _price > 0;
  }

  void _addPosition() {
    final newPosition = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'symbol': widget.asset['code']!,
      'name': widget.asset['name']!,
      'quantity': _quantity,
      'averageCost': _price,
      'currentPrice': widget.asset['buyPrice'] as double? ?? _price,
      'purchaseValue': _quantity * _price,
      'currentValue': _quantity * (widget.asset['buyPrice'] as double? ?? _price),
      'purchaseHistory': [
        {
          'quantity': _quantity,
          'price': _price,
          'date':
              '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
        }
      ],
      'priceHistory': List.generate(
          30, (index) => _price * (0.9 + (0.2 * (index % 10) / 10))),
    };

    widget.onAddPosition(newPosition);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Main content - scrollable area
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Top content - scrollable if needed
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 6.h),
                          _buildQuantitySection(),
                          SizedBox(height: 4.h),
                          _buildPriceSection(),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom content - fixed at bottom
                  Column(
                    children: [
                      _buildInfoText(),
                      SizedBox(height: 2.h),
                      _buildAddPositionButton(),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 8.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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

              // Asset code
              Text(
                widget.asset['code'] as String,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space for symmetry
              SizedBox(width: 12.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      children: [
        Text(
          'Miktar',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 2.h),
        
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: TextField(
            controller: _quantityController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 3,
                ),
              ),
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
              contentPadding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
              hintText: '100',
              suffix: Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: Text(
                  'adet',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 20.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            onChanged: (value) {
              final newQuantity = double.tryParse(value);
              if (newQuantity != null && newQuantity > 0) {
                setState(() {
                  _quantity = newQuantity;
                });
              } else {
                setState(() {
                  _quantity = 0.0;
                });
              }
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      children: [
        Text(
          'Satın Alma Fiyatı',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 2.h),
        
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: TextField(
            controller: _priceController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 3,
                ),
              ),
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
              contentPadding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
              hintText: '₺32,50',
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 20.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            onChanged: (value) {
              final cleanValue = value.replaceAll('₺', '').replaceAll(',', '.');
              final newPrice = double.tryParse(cleanValue);
              if (newPrice != null && newPrice > 0) {
                setState(() {
                  _price = newPrice;
                });
              } else {
                setState(() {
                  _price = 0.0;
                });
              }
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,₺]')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText() {
    final assetCode = widget.asset['code'] as String;
    final totalValue = _quantity * _price;
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        totalValue > 0 
          ? '$assetCode pozisyonu toplam ${CurrencyFormatter.formatTRY(totalValue, decimalPlaces: 2)} değerinde eklenecek'
          : 'Miktar ve fiyat girdiğinizde toplam değer burada görünecek',
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAddPositionButton() {
    return Container(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton(
        onPressed: _canAddPosition() ? _addPosition : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canAddPosition() 
            ? AppTheme.lightTheme.colorScheme.primary
            : Colors.grey[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: _canAddPosition() ? 4 : 0,
        ),
        child: Text(
          'POZİSYON EKLE',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// Edit Position Details Dialog for editing existing positions
class EditPositionDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> position;
  final Map<String, dynamic> asset;
  final Function(Map<String, dynamic>, double, double) onUpdatePosition;

  const EditPositionDetailsDialog({
    Key? key,
    required this.position,
    required this.asset,
    required this.onUpdatePosition,
  }) : super(key: key);

  @override
  State<EditPositionDetailsDialog> createState() => _EditPositionDetailsDialogState();
}

class _EditPositionDetailsDialogState extends State<EditPositionDetailsDialog> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  double _quantity = 0.0;
  double _price = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing position data
    _quantity = (widget.position['quantity'] as num?)?.toDouble() ?? 0.0;
    _price = (widget.position['purchasePrice'] as num?)?.toDouble() ?? 
             (widget.position['averageCost'] as num?)?.toDouble() ?? 0.0;
    
    _quantityController.text = _quantity.toString();
    _priceController.text = '₺${_price.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool _canUpdatePosition() {
    return _quantity > 0 && _price > 0;
  }

  void _updatePosition() {
    widget.onUpdatePosition(widget.position, _quantity, _price);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Main content - scrollable area
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Top content - scrollable if needed
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 6.h),
                          _buildQuantitySection(),
                          SizedBox(height: 4.h),
                          _buildPriceSection(),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom content - fixed at bottom
                  Column(
                    children: [
                      _buildInfoText(),
                      SizedBox(height: 2.h),
                      _buildUpdatePositionButton(),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 8.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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

              // Asset code with "Düzenle" prefix
              Text(
                '${widget.asset['code']} - Düzenle',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space for symmetry
              SizedBox(width: 12.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      children: [
        Text(
          'Miktar',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 2.h),
        
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: TextField(
            controller: _quantityController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 3,
                ),
              ),
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
              contentPadding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
              hintText: '100',
              suffix: Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: Text(
                  'adet',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 20.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            onChanged: (value) {
              final newQuantity = double.tryParse(value);
              if (newQuantity != null && newQuantity > 0) {
                setState(() {
                  _quantity = newQuantity;
                });
              } else {
                setState(() {
                  _quantity = 0.0;
                });
              }
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      children: [
        Text(
          'Satın Alma Fiyatı',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 2.h),
        
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: TextField(
            controller: _priceController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 3,
                ),
              ),
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
              contentPadding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
              hintText: '₺32,50',
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 20.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            onChanged: (value) {
              final cleanValue = value.replaceAll('₺', '').replaceAll(',', '.');
              final newPrice = double.tryParse(cleanValue);
              if (newPrice != null && newPrice > 0) {
                setState(() {
                  _price = newPrice;
                });
              } else {
                setState(() {
                  _price = 0.0;
                });
              }
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,₺]')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText() {
    final assetCode = widget.asset['code'] as String;
    final totalValue = _quantity * _price;
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        totalValue > 0 
          ? '$assetCode pozisyonu ${CurrencyFormatter.formatTRY(totalValue, decimalPlaces: 2)} değerinde güncellenecek'
          : 'Miktar ve fiyat girdiğinizde toplam değer burada görünecek',
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUpdatePositionButton() {
    return Container(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton(
        onPressed: _canUpdatePosition() ? _updatePosition : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canUpdatePosition() 
            ? AppTheme.lightTheme.colorScheme.primary
            : Colors.grey[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: _canUpdatePosition() ? 4 : 0,
        ),
        child: Text(
          'POZİSYONU GÜNCELLE',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}