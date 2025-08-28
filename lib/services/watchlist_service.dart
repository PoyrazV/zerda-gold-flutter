import 'package:flutter/material.dart';
import 'currency_api_service.dart';
import 'user_data_service.dart';

class WatchlistService {
  static final List<VoidCallback> _listeners = [];
  static final CurrencyApiService _currencyApiService = CurrencyApiService();
  // Use singleton instance of UserDataService
  static UserDataService get _userDataService => UserDataService();

  // Static method to get watchlist items for ticker
  static List<Map<String, dynamic>> getWatchlistItems() {
    return _userDataService.getWatchlistItems();
  }

  // Static method to add listener
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
    // Also listen to user data changes
    _userDataService.addListener(listener);
  }

  // Static method to remove listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    _userDataService.removeListener(listener);
  }

  // Notify all listeners
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Static method to add item to watchlist
  static Future<void> addToWatchlist(Map<String, dynamic> item) async {
    await _userDataService.addToWatchlist(item);
    _notifyListeners();
  }

  // Static method to remove item from watchlist
  static Future<void> removeFromWatchlist(String code) async {
    await _userDataService.removeFromWatchlist(code);
    _notifyListeners();
  }

  // Static method to check if item is in watchlist
  static bool isInWatchlist(String code) {
    return _userDataService.isInWatchlist(code);
  }

  // Method to update watchlist data (for refresh functionality)
  static Future<void> updateWatchlistData() async {
    try {
      print('WatchlistService: Updating watchlist data from API...');
      final apiData = await _currencyApiService.getFormattedCurrencyData();
      print('WatchlistService: Received ${apiData.length} currencies from API');

      // Get current watchlist items
      final watchlistItems = getWatchlistItems();
      
      // Update each watchlist item with API data
      for (var watchlistItem in watchlistItems) {
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
      
      // Save updated watchlist
      await _userDataService.saveWatchlist(watchlistItems);
      _notifyListeners();
      print('WatchlistService: Successfully updated ${watchlistItems.length} watchlist items');
    } catch (e) {
      print('WatchlistService: Error updating watchlist data: $e');
      // Fallback to mock data update on error
      final watchlistItems = getWatchlistItems();
      for (var item in watchlistItems) {
        final change = (DateTime.now().millisecond % 50 - 25) * 0.01;
        item['change'] = change;
        item['changePercent'] = change / (item['buyPrice'] as double) * 100;
        item['isPositive'] = change >= 0;
      }
      await _userDataService.saveWatchlist(watchlistItems);
      _notifyListeners();
    }
  }
}