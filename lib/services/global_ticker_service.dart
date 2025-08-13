import 'dart:async';
import 'package:flutter/foundation.dart';
import 'currency_api_service.dart';

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
    
    await _fetchTickerData();
    _startPeriodicRefresh();
  }

  // Fetch ticker data from API
  Future<void> _fetchTickerData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      print('GlobalTickerService: Fetching currency data from API...');
      final data = await _currencyApiService.getFormattedCurrencyData();
      print('GlobalTickerService: Received ${data.length} currencies from API');
      
      if (data.isNotEmpty) {
        // Select major currencies for ticker
        final majorCurrencies = ['USD', 'EUR', 'GBP', 'CHF'];
        final tickerCurrencies = data.where((currency) {
          final code = (currency['code'] as String).replaceAll('TRY', '');
          return majorCurrencies.contains(code);
        }).take(4).map((currency) => {
          'symbol': currency['code'],
          'price': ((currency['buyPrice'] as double? ?? 0.0) + (currency['sellPrice'] as double? ?? 0.0)) / 2,
          'change': currency['change'] as double? ?? 0.0,
          'changePercent': currency['change'] as double? ?? 0.0,
        }).toList();

        print('GlobalTickerService: Selected ${tickerCurrencies.length} major currencies for ticker');
        _tickerData = tickerCurrencies;
        _hasInitialData = true;
      }
    } catch (e) {
      print('GlobalTickerService API error: $e');
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

  // Get ticker data - returns API data if available, otherwise default data
  List<Map<String, dynamic>> getCurrentTickerData() {
    if (_tickerData.isNotEmpty) {
      return _tickerData;
    }
    return getDefaultData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}