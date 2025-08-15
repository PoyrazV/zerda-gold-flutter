import 'dart:async';
import 'financial_data_service.dart';
import 'watchlist_service.dart';

class TickerDataService {
  static final TickerDataService _instance = TickerDataService._internal();
  factory TickerDataService() => _instance;
  TickerDataService._internal() {
    // Listen to watchlist changes
    WatchlistService.addListener(_onWatchlistChanged);
  }

  final FinancialDataService _dataService = FinancialDataService();
  List<Map<String, dynamic>> _tickerData = [];
  bool _isLoading = false;
  DateTime? _lastUpdateTime;
  
  // Stream controller for broadcasting ticker data updates
  final StreamController<List<Map<String, dynamic>>> _tickerController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Public stream for widgets to listen to
  Stream<List<Map<String, dynamic>>> get tickerStream => _tickerController.stream;
  
  // Get current ticker data
  List<Map<String, dynamic>> get currentTickerData => _tickerData;
  
  // Check if data is fresh (less than 5 minutes old)
  bool get isDataFresh {
    if (_lastUpdateTime == null) return false;
    return DateTime.now().difference(_lastUpdateTime!).inMinutes < 5;
  }

  Future<void> loadTickerData({bool forceRefresh = false}) async {
    // Don't load if already loading or data is fresh
    if (_isLoading || (!forceRefresh && isDataFresh && _tickerData.isNotEmpty)) {
      return;
    }

    _isLoading = true;
    
    try {
      final currencyData = await _dataService.getRealCurrencyData();
      if (currencyData.isNotEmpty) {
        final tickerCurrencies = _selectTickerCurrencies(currencyData);
        
        _tickerData = tickerCurrencies;
        _lastUpdateTime = DateTime.now();
        
        // Broadcast the new data to all listeners
        _tickerController.add(_tickerData);
        
        print('TickerDataService: ${tickerCurrencies.length} para birimi güncellendi');
      }
    } catch (e) {
      print('TickerDataService hatası: $e');
    } finally {
      _isLoading = false;
    }
  }

  List<Map<String, dynamic>> _selectTickerCurrencies(List<Map<String, dynamic>> allCurrencies) {
    // Get user's watchlist items
    final watchlistItems = WatchlistService.getWatchlistItems();
    List<Map<String, dynamic>> tickerData = [];
    
    if (watchlistItems.isNotEmpty) {
      // First priority: Show currencies from user's watchlist with API data
      for (final watchlistItem in watchlistItems) {
        final code = watchlistItem['code'] as String;
        
        // Try to find this currency in API data
        final apiCurrency = allCurrencies.firstWhere(
          (c) => c['code'] == code || c['code'] == code.replaceAll('/EUR', 'EUR'),
          orElse: () => <String, dynamic>{},
        );
        
        if (apiCurrency.isNotEmpty) {
          // Use API data for this watchlist item
          final buyPrice = apiCurrency['buyPrice'] as double? ?? 0.0;
          final sellPrice = apiCurrency['sellPrice'] as double? ?? 0.0;
          final avgPrice = (buyPrice + sellPrice) / 2;
          
          tickerData.add({
            'symbol': code,
            'price': avgPrice,
            'change': apiCurrency['change'] as double? ?? 0.0,
            'changePercent': apiCurrency['change'] as double? ?? 0.0,
            'lastUpdate': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          // Fallback to watchlist data if not found in API
          tickerData.add({
            'symbol': code,
            'price': watchlistItem['buyPrice'] as double? ?? 0.0,
            'change': watchlistItem['change'] as double? ?? 0.0,
            'changePercent': watchlistItem['changePercent'] as double? ?? 0.0,
            'lastUpdate': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
      
      print('TickerDataService: ${tickerData.length} takip listesi kıymeti gösteriliyor');
    } else {
      // If no watchlist items, show default popular currencies
      final defaultCodes = ['USDTRY', 'EURTRY', 'GBPTRY'];
      
      for (final code in defaultCodes) {
        final currency = allCurrencies.firstWhere(
          (c) => c['code'] == code,
          orElse: () => <String, dynamic>{},
        );
        if (currency.isNotEmpty) {
          final buyPrice = currency['buyPrice'] as double? ?? 0.0;
          final sellPrice = currency['sellPrice'] as double? ?? 0.0;
          final avgPrice = (buyPrice + sellPrice) / 2;
          
          tickerData.add({
            'symbol': currency['code'],
            'price': avgPrice,
            'change': currency['change'] as double? ?? 0.0,
            'changePercent': currency['change'] as double? ?? 0.0,
            'lastUpdate': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
      
      print('TickerDataService: ${tickerData.length} varsayılan kıymet gösteriliyor (takip listesi boş)');
    }
    
    return tickerData;
  }

  // Force refresh ticker data
  Future<void> refreshTickerData() async {
    await loadTickerData(forceRefresh: true);
  }

  // Watchlist change handler
  void _onWatchlistChanged() {
    // Refresh ticker data when watchlist changes
    refreshTickerData();
  }

  // Clean up
  void dispose() {
    WatchlistService.removeListener(_onWatchlistChanged);
    _tickerController.close();
  }
}