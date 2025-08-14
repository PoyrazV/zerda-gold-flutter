import 'dart:async';
import 'package:flutter/foundation.dart';
import 'currency_api_service.dart';
import 'watchlist_service.dart';

class GlobalTickerService extends ChangeNotifier {
  static final GlobalTickerService _instance = GlobalTickerService._internal();
  factory GlobalTickerService() => _instance;
  GlobalTickerService._internal();

  final CurrencyApiService _currencyApiService = CurrencyApiService();
  
  List<Map<String, dynamic>> _tickerData = [];
  bool _isLoading = false;
  bool _hasInitialData = false;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> get tickerData => _tickerData;
  bool get isLoading => _isLoading;
  bool get hasData => _tickerData.isNotEmpty;
  bool get hasInitialData => _hasInitialData;

  // Initialize the service and start fetching data
  Future<void> initialize() async {
    if (_hasInitialData) return; // Already initialized
    
    // Listen to watchlist changes
    WatchlistService.addListener(_onWatchlistChanged);
    
    await _fetchTickerData();
    _startPeriodicRefresh();
  }

  // Handle watchlist changes
  void _onWatchlistChanged() {
    _fetchTickerData();
  }

  // Fetch ticker data from API
  Future<void> _fetchTickerData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Get watchlist items
      final watchlistItems = WatchlistService.getWatchlistItems();
      print('GlobalTickerService: Found ${watchlistItems.length} items in watchlist');

      if (watchlistItems.isNotEmpty) {
        // Get API data and match with watchlist items
        print('GlobalTickerService: Fetching API data for watchlist items...');
        final apiData = await _currencyApiService.getFormattedCurrencyData();
        print('GlobalTickerService: Received ${apiData.length} currencies from API');
        
        List<Map<String, dynamic>> updatedTickerData = [];
        
        for (var watchlistItem in watchlistItems) {
          final itemCode = watchlistItem['code'] as String;
          
          // Find matching API data for this watchlist item
          final matchingApiData = apiData.firstWhere(
            (apiItem) => apiItem['code'] == itemCode,
            orElse: () => <String, dynamic>{},
          );
          
          if (matchingApiData.isNotEmpty) {
            // Use API data for this watchlist item
            updatedTickerData.add({
              'symbol': matchingApiData['code'],
              'price': ((matchingApiData['buyPrice'] as double? ?? 0.0) + (matchingApiData['sellPrice'] as double? ?? 0.0)) / 2,
              'change': matchingApiData['change'] as double? ?? 0.0,
              'changePercent': matchingApiData['change'] as double? ?? 0.0,
            });
          } else {
            // Fallback to watchlist data if API doesn't have this item
            updatedTickerData.add({
              'symbol': itemCode,
              'price': watchlistItem['buyPrice'],
              'change': watchlistItem['change'],
              'changePercent': watchlistItem['changePercent'],
            });
          }
        }
        
        _tickerData = updatedTickerData;
        print('GlobalTickerService: Updated ${_tickerData.length} watchlist items with API data for ticker');
        _hasInitialData = true;
      } else {
        // If watchlist is empty, fetch API data for major currencies as fallback
        print('GlobalTickerService: Watchlist empty, fetching major currencies from API...');
        final data = await _currencyApiService.getFormattedCurrencyData();
        print('GlobalTickerService: Received ${data.length} currencies from API');
        
        if (data.isNotEmpty) {
          // Select major currencies for ticker as fallback
          final majorCurrencies = ['USD/TRY', 'EUR/TRY', 'GBP/TRY', 'GRAM'];
          final tickerCurrencies = <Map<String, dynamic>>[];
          
          for (final targetCode in majorCurrencies) {
            final currency = data.firstWhere(
              (curr) => curr['code'] == targetCode,
              orElse: () => <String, dynamic>{},
            );
            
            if (currency.isNotEmpty) {
              tickerCurrencies.add({
                'symbol': currency['code'],
                'price': ((currency['buyPrice'] as double? ?? 0.0) + (currency['sellPrice'] as double? ?? 0.0)) / 2,
                'change': currency['change'] as double? ?? 0.0,
                'changePercent': currency['change'] as double? ?? 0.0,
              });
            }
          }

          print('GlobalTickerService: Selected ${tickerCurrencies.length} major currencies as fallback');
          _tickerData = tickerCurrencies;
          _hasInitialData = true;
        }
      }
    } catch (e) {
      print('GlobalTickerService error: $e');
      // Don't update _hasInitialData if there was an error and we don't have any data yet
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start periodic refresh every 30 seconds
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchTickerData();
    });
  }

  // Manual refresh
  Future<void> refresh() async {
    await _fetchTickerData();
  }

  // Get default data if no API data is available
  List<Map<String, dynamic>> getDefaultData() {
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

  // Get ticker data - returns API data if available, otherwise try to fetch major currencies
  List<Map<String, dynamic>> getCurrentTickerData() {
    if (_tickerData.isNotEmpty) {
      return _tickerData;
    }
    
    // If we don't have data and we're not currently loading, try to fetch major currencies
    if (!_isLoading && !_hasInitialData) {
      _fetchTickerData();
    }
    
    return _tickerData;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WatchlistService.removeListener(_onWatchlistChanged);
    super.dispose();
  }
}