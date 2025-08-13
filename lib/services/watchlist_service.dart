import 'package:flutter/material.dart';
import 'currency_api_service.dart';

class WatchlistService {
  static final List<VoidCallback> _listeners = [];
  static final CurrencyApiService _currencyApiService = CurrencyApiService();
  static List<Map<String, dynamic>> _watchlistItems = [
    {
      'code': 'USD/TRY',
      'name': 'Amerikan Doları',
      'buyPrice': 34.2156,
      'sellPrice': 34.2389,
      'change': 0.0234,
      'changePercent': 0.068,
      'isPositive': true,
    },
    {
      'code': 'EUR/TRY', 
      'name': 'Euro',
      'buyPrice': 37.1234,
      'sellPrice': 37.1456,
      'change': -0.0456,
      'changePercent': -0.123,
      'isPositive': false,
    },
    {
      'code': 'GOLD',
      'name': 'Altın (Ons)',
      'buyPrice': 2847.50,
      'sellPrice': 2849.20,
      'change': -12.50,
      'changePercent': -0.437,
      'isPositive': false,
    },
  ];

  // Static method to get watchlist items for ticker
  static List<Map<String, dynamic>> getWatchlistItems() {
    return List.from(_watchlistItems);
  }

  // Static method to add listener
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Static method to remove listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Static method to add item to watchlist
  static void addToWatchlist(Map<String, dynamic> item) {
    if (!_watchlistItems.any((element) => element['code'] == item['code'])) {
      _watchlistItems.add(item);
      _notifyListeners();
    }
  }

  // Static method to remove item from watchlist
  static void removeFromWatchlist(String code) {
    _watchlistItems.removeWhere((item) => item['code'] == code);
    _notifyListeners();
  }

  // Static method to check if item is in watchlist
  static bool isInWatchlist(String code) {
    return _watchlistItems.any((item) => item['code'] == code);
  }

  // Method to update watchlist data (for refresh functionality)
  static Future<void> updateWatchlistData() async {
    try {
      print('WatchlistService: Updating watchlist data from API...');
      final apiData = await _currencyApiService.getFormattedCurrencyData();
      print('WatchlistService: Received ${apiData.length} currencies from API');

      // Update each watchlist item with API data
      for (var watchlistItem in _watchlistItems) {
        final itemCode = watchlistItem['code'] as String;
        
        // Find matching API data for this watchlist item
        final matchingApiData = apiData.firstWhere(
          (apiItem) => apiItem['code'] == itemCode,
          orElse: () => <String, dynamic>{},
        );
        
        if (matchingApiData.isNotEmpty) {
          // Update with real API data
          watchlistItem['buyPrice'] = matchingApiData['buyPrice'];
          watchlistItem['sellPrice'] = matchingApiData['sellPrice'];
          watchlistItem['change'] = matchingApiData['change'];
          watchlistItem['changePercent'] = matchingApiData['change'];
          watchlistItem['isPositive'] = (matchingApiData['change'] as double? ?? 0.0) >= 0;
          print('WatchlistService: Updated $itemCode with API data');
        } else {
          // Fallback: generate mock change if API doesn't have this currency
          final change = (DateTime.now().millisecond % 50 - 25) * 0.01;
          watchlistItem['change'] = change;
          watchlistItem['changePercent'] = change / (watchlistItem['buyPrice'] as double) * 100;
          watchlistItem['isPositive'] = change >= 0;
          print('WatchlistService: Updated $itemCode with fallback data (API not available)');
        }
      }
      
      _notifyListeners();
      print('WatchlistService: Successfully updated ${_watchlistItems.length} watchlist items');
    } catch (e) {
      print('WatchlistService: Error updating watchlist data: $e');
      // Fallback to mock data update on error
      for (var item in _watchlistItems) {
        final change = (DateTime.now().millisecond % 50 - 25) * 0.01;
        item['change'] = change;
        item['changePercent'] = change / (item['buyPrice'] as double) * 100;
        item['isPositive'] = change >= 0;
      }
      _notifyListeners();
    }
  }
}