import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header.dart';
import '../../widgets/price_ticker.dart';
import './widgets/add_position_bottom_sheet.dart';
import './widgets/empty_portfolio_state.dart';
import './widgets/portfolio_summary_card.dart';
import './widgets/position_card.dart';

class PortfolioManagementScreen extends StatefulWidget {
  const PortfolioManagementScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioManagementScreen> createState() =>
      _PortfolioManagementScreenState();
}

class _PortfolioManagementScreenState extends State<PortfolioManagementScreen>
    with TickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  List<Map<String, dynamic>> _positions = [
    {
      'id': 1,
      'symbol': 'USD/TRY',
      'name': 'Amerikan Doları',
      'quantity': 1000.0,
      'averageCost': 32.15,
      'currentPrice': 33.42,
      'purchaseValue': 32150.0,
      'currentValue': 33420.0,
      'purchaseHistory': [
        {'quantity': 500.0, 'price': 31.80, 'date': '15/07/2024'},
        {'quantity': 300.0, 'price': 32.25, 'date': '22/07/2024'},
        {'quantity': 200.0, 'price': 32.90, 'date': '28/07/2024'},
      ],
      'priceHistory': [
        31.20,
        31.45,
        31.80,
        32.10,
        32.25,
        32.50,
        32.80,
        33.10,
        33.25,
        33.42
      ],
    },
    {
      'id': 2,
      'symbol': 'GOLD',
      'name': 'Altın (Ons)',
      'quantity': 5.0,
      'averageCost': 2850.0,
      'currentPrice': 2920.0,
      'purchaseValue': 14250.0,
      'currentValue': 14600.0,
      'purchaseHistory': [
        {'quantity': 2.0, 'price': 2820.0, 'date': '10/07/2024'},
        {'quantity': 3.0, 'price': 2870.0, 'date': '20/07/2024'},
      ],
      'priceHistory': [
        2800,
        2820,
        2845,
        2860,
        2870,
        2885,
        2900,
        2910,
        2915,
        2920
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
    
    // Listen to watchlist changes to update ticker
    WatchlistService.addListener(_updateTicker);
  }

  void _updateTicker() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WatchlistService.removeListener(_updateTicker);
    _fabAnimationController.dispose();
    super.dispose();
  }

  double get _totalPortfolioValue {
    return _positions.fold(0.0,
        (sum, position) => sum + (position['currentValue'] as num).toDouble());
  }

  double get _totalPurchaseValue {
    return _positions.fold(0.0,
        (sum, position) => sum + (position['purchaseValue'] as num).toDouble());
  }

  double get _totalGainLoss {
    return _totalPortfolioValue - _totalPurchaseValue;
  }

  double get _totalGainLossPercentage {
    if (_totalPurchaseValue == 0) return 0.0;
    return (_totalGainLoss / _totalPurchaseValue) * 100;
  }

  double get _dailyChange {
    // Simulated daily change calculation
    return _positions.fold(0.0, (sum, position) {
      final currentValue = (position['currentValue'] as num).toDouble();
      final dailyChangePercent = (DateTime.now().millisecond % 10 - 5) / 100;
      return sum + (currentValue * dailyChangePercent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Header with ZERDA branding
          const AppHeader(),

          // Price ticker
          _buildPriceTicker(),

          // Main content
          Expanded(
            child: _positions.isEmpty ? _buildEmptyState() : _buildPortfolioContent(),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _showAddPositionBottomSheet,
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: Colors.white,
          child: CustomIconWidget(
            iconName: 'add',
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEmptyState() {
    return EmptyPortfolioState(
      onAddFirstPosition: _showAddPositionBottomSheet,
    );
  }

  Widget _buildPortfolioContent() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshPortfolio,
      color: AppTheme.lightTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PortfolioSummaryCard(
              totalValue: _totalPortfolioValue,
              gainLossPercentage: _totalGainLossPercentage,
              dailyChange: _dailyChange,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pozisyonlarım',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _sortPositions,
                    icon: CustomIconWidget(
                      iconName: 'sort',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 18,
                    ),
                    label: Text(
                      'Sırala',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final position = _positions[index];
                return PositionCard(
                  position: position,
                  onEdit: () => _editPosition(position),
                  onSetTarget: () => _setTargetPrice(position),
                  onRemove: () => _removePosition(position),
                  onDuplicate: () => _duplicatePosition(position),
                  onExport: () => _exportPositionData(position),
                  onPriceAlert: () => _createPriceAlert(position),
                );
              },
              childCount: _positions.length,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 10.h),
          ),
        ],
      ),
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

              // ZERDA title
              Text(
                'ZERDA',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Profile button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/user-profile-screen');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/images/default_profile.png'),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Fallback to icon if image fails to load
                      },
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTicker() {
    // Use shared PriceTicker widget
    return PriceTicker();
  }

  Widget _buildPriceTickerOld() {
    // Show watchlist items in ticker
    final watchlistItems = WatchlistService.getWatchlistItems();
    final tickerData = watchlistItems.isEmpty 
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
        : watchlistItems.map((item) => {
            'symbol': item['code'],
            'price': item['buyPrice'],
            'change': item['change'],
            'changePercent': item['changePercent']
          }).toList();

    return Container(
      height: 9.h,
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

          final data = tickerData[index]; // Remove the % operation
          final bool isPositive = (data['change'] as double) >= 0;

          return Container(
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
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigationBar(currentRoute: '/portfolio-management-screen');
  }

  Future<void> _refreshPortfolio() async {
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      // Simulate price updates
      for (var position in _positions) {
        final currentPrice = (position['currentPrice'] as num).toDouble();
        final priceChange = (DateTime.now().millisecond % 20 - 10) / 100;
        final newPrice = currentPrice * (1 + priceChange);

        position['currentPrice'] = newPrice;
        position['currentValue'] =
            (position['quantity'] as num).toDouble() * newPrice;

        // Update price history
        final priceHistory = position['priceHistory'] as List;
        priceHistory.removeAt(0);
        priceHistory.add(newPrice);
      }
    });

    Fluttertoast.showToast(
      msg: "Portföy güncellendi",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.positiveGreen,
      textColor: Colors.white,
    );
  }

  void _showAddPositionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPositionBottomSheet(
        onAddPosition: _addPosition,
      ),
    );
  }

  void _addPosition(Map<String, dynamic> newPosition) {
    setState(() {
      _positions.add(newPosition);
    });

    Fluttertoast.showToast(
      msg: "Pozisyon eklendi",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.positiveGreen,
      textColor: Colors.white,
    );
  }

  void _editPosition(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pozisyon Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Yeni Miktar',
                suffixText: 'adet',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              controller:
                  TextEditingController(text: position['quantity'].toString()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Pozisyon güncellendi",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: AppTheme.positiveGreen,
                textColor: Colors.white,
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _setTargetPrice(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedef Fiyat Belirle'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Hedef Fiyat',
            prefixText: '₺ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Hedef fiyat belirlendi",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: AppTheme.alertOrange,
                textColor: Colors.white,
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _removePosition(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pozisyonu Kaldır'),
        content: Text(
            '${position['name']} pozisyonunu portföyünüzden kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _positions.removeWhere((p) => p['id'] == position['id']);
              });
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Pozisyon kaldırıldı",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: AppTheme.negativeRed,
                textColor: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.negativeRed,
            ),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }

  void _duplicatePosition(Map<String, dynamic> position) {
    final duplicatedPosition = Map<String, dynamic>.from(position);
    duplicatedPosition['id'] = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _positions.add(duplicatedPosition);
    });

    Fluttertoast.showToast(
      msg: "Pozisyon kopyalandı",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.positiveGreen,
      textColor: Colors.white,
    );
  }

  void _exportPositionData(Map<String, dynamic> position) {
    Fluttertoast.showToast(
      msg: "Veri dışa aktarılıyor...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.primaryColor,
      textColor: Colors.white,
    );
  }

  void _createPriceAlert(Map<String, dynamic> position) {
    Navigator.pushNamed(context, '/price-alerts-screen');
  }

  void _sortPositions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sıralama Seçenekleri',
              style: AppTheme.lightTheme.textTheme.headlineSmall,
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'trending_up',
                color: AppTheme.positiveGreen,
                size: 24,
              ),
              title: const Text('Kazanca Göre (Yüksekten Düşüğe)'),
              onTap: () {
                _sortPositionsByGain(descending: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'trending_down',
                color: AppTheme.negativeRed,
                size: 24,
              ),
              title: const Text('Kazanca Göre (Düşükten Yükseğe)'),
              onTap: () {
                _sortPositionsByGain(descending: false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'account_balance_wallet',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Değere Göre (Yüksekten Düşüğe)'),
              onTap: () {
                _sortPositionsByValue(descending: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'sort_by_alpha',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              title: const Text('İsme Göre (A-Z)'),
              onTap: () {
                _sortPositionsByName();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sortPositionsByGain({required bool descending}) {
    setState(() {
      _positions.sort((a, b) {
        final aGain = (a['currentValue'] as num).toDouble() -
            (a['purchaseValue'] as num).toDouble();
        final bGain = (b['currentValue'] as num).toDouble() -
            (b['purchaseValue'] as num).toDouble();
        return descending ? bGain.compareTo(aGain) : aGain.compareTo(bGain);
      });
    });
  }

  void _sortPositionsByValue({required bool descending}) {
    setState(() {
      _positions.sort((a, b) {
        final aValue = (a['currentValue'] as num).toDouble();
        final bValue = (b['currentValue'] as num).toDouble();
        return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
      });
    });
  }

  void _sortPositionsByName() {
    setState(() {
      _positions
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    });
  }

  void _showPortfolioMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Portföyü Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                _exportPortfolio();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Portföyü Paylaş'),
              onTap: () {
                Navigator.pop(context);
                _sharePortfolio();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              title: const Text('Portföy Ayarları'),
              onTap: () {
                Navigator.pop(context);
                _showPortfolioSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportPortfolio() {
    Fluttertoast.showToast(
      msg: "Portföy dışa aktarılıyor...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.primaryColor,
      textColor: Colors.white,
    );
  }

  void _sharePortfolio() {
    Fluttertoast.showToast(
      msg: "Portföy paylaşılıyor...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.primaryColor,
      textColor: Colors.white,
    );
  }

  void _showPortfolioSettings() {
    Navigator.pushNamed(context, '/user-profile-screen');
  }}
