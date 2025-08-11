import 'package:flutter/material.dart';

class WatchlistService {
  static final List<VoidCallback> _listeners = [];
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
  static void updateWatchlistData() {
    for (var item in _watchlistItems) {
      final change = (DateTime.now().millisecond % 50 - 25) * 0.01;
      item['change'] = change;
      item['changePercent'] = change / (item['buyPrice'] as double) * 100;
      item['isPositive'] = change >= 0;
    }
  }
}