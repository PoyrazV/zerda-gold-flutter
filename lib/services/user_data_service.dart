import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class UserDataService extends ChangeNotifier {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final AuthService _authService = AuthService();
  late Dio _dio;
  
  // API configuration
  static const String _apiBaseUrl = 'http://10.0.2.2:3009/api/mobile';
  
  // Current user data
  String? _currentUserId;
  Map<String, dynamic> _watchlist = {};
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> _activeAlerts = [];
  List<Map<String, dynamic>> _historyAlerts = [];
  
  // Getters
  Map<String, dynamic> get watchlist => Map.from(_watchlist);
  List<Map<String, dynamic>> get portfolio => List.from(_portfolio);
  List<Map<String, dynamic>> get activeAlerts => List.from(_activeAlerts);
  List<Map<String, dynamic>> get historyAlerts => List.from(_historyAlerts);
  
  // Initialize service
  Future<void> initialize() async {
    print('🔄 UserDataService: Initializing...');
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    // Listen to auth changes
    _authService.addListener(_onAuthChanged);
    print('🔄 UserDataService: Added auth listener');
    
    // Load data for current user if logged in
    if (_authService.isLoggedIn) {
      print('✅ UserDataService: User is logged in, userId: ${_authService.userId}');
      await loadUserData(_authService.userId);
    } else {
      print('⚠️ UserDataService: User is not logged in at initialization');
    }
  }
  
  // Handle auth state changes
  void _onAuthChanged() async {
    print('🔔 UserDataService: Auth state changed - isLoggedIn: ${_authService.isLoggedIn}, userId: ${_authService.userId}, currentUserId: $_currentUserId');
    
    if (_authService.isLoggedIn && _authService.userId != _currentUserId) {
      // User logged in or switched
      print('✅ UserDataService: User logged in or switched, loading data for userId: ${_authService.userId}');
      await loadUserData(_authService.userId);
    } else if (!_authService.isLoggedIn && _currentUserId != null) {
      // User logged out
      print('👋 UserDataService: User logged out, clearing data');
      await clearCurrentUserData();
    }
  }
  
  // Load user data from storage and/or backend
  Future<void> loadUserData(String? userId) async {
    if (userId == null) return;
    
    _currentUserId = userId;
    print('UserDataService: Loading data for user $userId');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load watchlist
      final watchlistKey = 'user_${userId}_watchlist';
      final watchlistJson = prefs.getString(watchlistKey);
      if (watchlistJson != null) {
        _watchlist = Map<String, dynamic>.from(jsonDecode(watchlistJson));
      }
      
      // Load portfolio
      final portfolioKey = 'user_${userId}_portfolio';
      final portfolioJson = prefs.getString(portfolioKey);
      if (portfolioJson != null) {
        final List<dynamic> portfolioList = jsonDecode(portfolioJson);
        _portfolio = portfolioList.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      // Load active alerts
      final activeAlertsKey = 'user_${userId}_active_alerts';
      final activeAlertsJson = prefs.getString(activeAlertsKey);
      if (activeAlertsJson != null) {
        final List<dynamic> alertsList = jsonDecode(activeAlertsJson);
        _activeAlerts = alertsList.map((alert) {
          final alertMap = Map<String, dynamic>.from(alert);
          // Convert date strings back to DateTime
          if (alertMap['createdAt'] is String) {
            alertMap['createdAt'] = DateTime.parse(alertMap['createdAt']);
          }
          return alertMap;
        }).toList();
      }
      
      // Load history alerts
      final historyAlertsKey = 'user_${userId}_history_alerts';
      final historyAlertsJson = prefs.getString(historyAlertsKey);
      if (historyAlertsJson != null) {
        final List<dynamic> historyList = jsonDecode(historyAlertsJson);
        _historyAlerts = historyList.map((alert) {
          final alertMap = Map<String, dynamic>.from(alert);
          if (alertMap['createdAt'] is String) {
            alertMap['createdAt'] = DateTime.parse(alertMap['createdAt']);
          }
          if (alertMap['triggeredAt'] is String) {
            alertMap['triggeredAt'] = DateTime.parse(alertMap['triggeredAt']);
          }
          return alertMap;
        }).toList();
      }
      
      notifyListeners();
      
      // Try to sync with backend
      await _syncWithBackend();
      
    } catch (e) {
      print('UserDataService: Error loading user data: $e');
    }
  }
  
  // Clear current user data (on logout)
  Future<void> clearCurrentUserData() async {
    print('UserDataService: Clearing data for user $_currentUserId');
    
    _currentUserId = null;
    _watchlist = {};
    _portfolio = [];
    _activeAlerts = [];
    _historyAlerts = [];
    
    notifyListeners();
  }
  
  // Save watchlist
  Future<void> saveWatchlist(List<Map<String, dynamic>> items) async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_${_currentUserId}_watchlist';
      
      // Convert list to map for easier lookup
      _watchlist = {};
      for (var item in items) {
        _watchlist[item['code']] = item;
      }
      
      await prefs.setString(key, jsonEncode(_watchlist));
      notifyListeners();
      
      // Sync with backend
      _syncWatchlistToBackend();
    } catch (e) {
      print('UserDataService: Error saving watchlist: $e');
    }
  }
  
  // Add to watchlist
  Future<void> addToWatchlist(Map<String, dynamic> item) async {
    print('📝 UserDataService: addToWatchlist called for ${item['code']}, currentUserId: $_currentUserId');
    
    // Try to get userId if null
    if (_currentUserId == null) {
      print('⚠️ UserDataService: currentUserId is null, trying to get from AuthService...');
      if (_authService.isLoggedIn && _authService.userId != null) {
        _currentUserId = _authService.userId;
        print('✅ UserDataService: Retrieved userId from AuthService: $_currentUserId');
      } else {
        print('❌ UserDataService: Cannot add to watchlist - no user logged in');
        return;
      }
    }
    
    _watchlist[item['code']] = item;
    print('✅ UserDataService: Added ${item['code']} to in-memory watchlist');
    
    await _saveWatchlistToStorage();
    print('✅ UserDataService: Saved watchlist to storage');
    
    notifyListeners();
    
    // Sync with backend
    _syncWatchlistToBackend();
  }
  
  // Remove from watchlist
  Future<void> removeFromWatchlist(String code) async {
    print('🗑️ UserDataService: removeFromWatchlist called for $code, currentUserId: $_currentUserId');
    
    // Try to get userId if null
    if (_currentUserId == null) {
      print('⚠️ UserDataService: currentUserId is null, trying to get from AuthService...');
      if (_authService.isLoggedIn && _authService.userId != null) {
        _currentUserId = _authService.userId;
        print('✅ UserDataService: Retrieved userId from AuthService: $_currentUserId');
      } else {
        print('❌ UserDataService: Cannot remove from watchlist - no user logged in');
        return;
      }
    }
    
    _watchlist.remove(code);
    print('✅ UserDataService: Removed $code from in-memory watchlist');
    
    await _saveWatchlistToStorage();
    print('✅ UserDataService: Saved watchlist to storage');
    
    notifyListeners();
    
    // Sync with backend
    _syncWatchlistToBackend();
  }
  
  // Check if in watchlist
  bool isInWatchlist(String code) {
    return _watchlist.containsKey(code);
  }
  
  // Get watchlist as list
  List<Map<String, dynamic>> getWatchlistItems() {
    return _watchlist.values.cast<Map<String, dynamic>>().toList();
  }
  
  // Save portfolio
  Future<void> savePortfolio(List<Map<String, dynamic>> positions) async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_${_currentUserId}_portfolio';
      
      _portfolio = List.from(positions);
      await prefs.setString(key, jsonEncode(_portfolio));
      notifyListeners();
      
      // Sync with backend
      _syncPortfolioToBackend();
    } catch (e) {
      print('UserDataService: Error saving portfolio: $e');
    }
  }
  
  // Save alerts
  Future<void> saveAlerts({
    List<Map<String, dynamic>>? activeAlerts,
    List<Map<String, dynamic>>? historyAlerts,
  }) async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save active alerts
      if (activeAlerts != null) {
        _activeAlerts = List.from(activeAlerts);
        final activeKey = 'user_${_currentUserId}_active_alerts';
        
        // Convert DateTime to string for storage
        final activeForStorage = _activeAlerts.map((alert) {
          final alertCopy = Map<String, dynamic>.from(alert);
          if (alertCopy['createdAt'] is DateTime) {
            alertCopy['createdAt'] = (alertCopy['createdAt'] as DateTime).toIso8601String();
          }
          return alertCopy;
        }).toList();
        
        await prefs.setString(activeKey, jsonEncode(activeForStorage));
      }
      
      // Save history alerts
      if (historyAlerts != null) {
        _historyAlerts = List.from(historyAlerts);
        final historyKey = 'user_${_currentUserId}_history_alerts';
        
        // Convert DateTime to string for storage
        final historyForStorage = _historyAlerts.map((alert) {
          final alertCopy = Map<String, dynamic>.from(alert);
          if (alertCopy['createdAt'] is DateTime) {
            alertCopy['createdAt'] = (alertCopy['createdAt'] as DateTime).toIso8601String();
          }
          if (alertCopy['triggeredAt'] is DateTime) {
            alertCopy['triggeredAt'] = (alertCopy['triggeredAt'] as DateTime).toIso8601String();
          }
          return alertCopy;
        }).toList();
        
        await prefs.setString(historyKey, jsonEncode(historyForStorage));
      }
      
      notifyListeners();
      
      // Sync with backend
      _syncAlertsToBackend();
    } catch (e) {
      print('UserDataService: Error saving alerts: $e');
    }
  }
  
  // Private helper to save watchlist to storage
  Future<void> _saveWatchlistToStorage() async {
    if (_currentUserId == null) {
      print('❌ UserDataService: Cannot save watchlist - currentUserId is null');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_${_currentUserId}_watchlist';
      final watchlistJson = jsonEncode(_watchlist);
      await prefs.setString(key, watchlistJson);
      print('💾 UserDataService: Saved watchlist to key: $key, items count: ${_watchlist.length}');
    } catch (e) {
      print('❌ UserDataService: Error saving watchlist to storage: $e');
    }
  }
  
  // Sync with backend
  Future<void> _syncWithBackend() async {
    if (_currentUserId == null || _authService.authToken == null) return;
    
    try {
      // Fetch user data from backend
      final response = await _dio.get(
        '/user/data',
        options: Options(
          headers: {'Authorization': 'Bearer ${_authService.authToken}'},
        ),
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // Update local data with backend data
        if (data['watchlist'] != null) {
          _watchlist = Map<String, dynamic>.from(data['watchlist']);
        }
        
        if (data['portfolio'] != null) {
          _portfolio = List<Map<String, dynamic>>.from(data['portfolio']);
        }
        
        if (data['alerts'] != null) {
          // Process alerts
          if (data['alerts']['active'] != null) {
            _activeAlerts = (data['alerts']['active'] as List).map((alert) {
              final alertMap = Map<String, dynamic>.from(alert);
              if (alertMap['createdAt'] is String) {
                alertMap['createdAt'] = DateTime.parse(alertMap['createdAt']);
              }
              return alertMap;
            }).toList();
          }
          
          if (data['alerts']['history'] != null) {
            _historyAlerts = (data['alerts']['history'] as List).map((alert) {
              final alertMap = Map<String, dynamic>.from(alert);
              if (alertMap['createdAt'] is String) {
                alertMap['createdAt'] = DateTime.parse(alertMap['createdAt']);
              }
              if (alertMap['triggeredAt'] is String) {
                alertMap['triggeredAt'] = DateTime.parse(alertMap['triggeredAt']);
              }
              return alertMap;
            }).toList();
          }
        }
        
        // Save to local storage
        await _saveAllToStorage();
        notifyListeners();
        
        print('UserDataService: Successfully synced with backend');
      }
    } catch (e) {
      print('UserDataService: Backend sync failed (using local data): $e');
      // Continue with local data if backend is unavailable
    }
  }
  
  // Save all data to storage
  Future<void> _saveAllToStorage() async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save watchlist
      await prefs.setString('user_${_currentUserId}_watchlist', jsonEncode(_watchlist));
      
      // Save portfolio
      await prefs.setString('user_${_currentUserId}_portfolio', jsonEncode(_portfolio));
      
      // Save alerts
      final activeForStorage = _activeAlerts.map((alert) {
        final alertCopy = Map<String, dynamic>.from(alert);
        if (alertCopy['createdAt'] is DateTime) {
          alertCopy['createdAt'] = (alertCopy['createdAt'] as DateTime).toIso8601String();
        }
        return alertCopy;
      }).toList();
      
      final historyForStorage = _historyAlerts.map((alert) {
        final alertCopy = Map<String, dynamic>.from(alert);
        if (alertCopy['createdAt'] is DateTime) {
          alertCopy['createdAt'] = (alertCopy['createdAt'] as DateTime).toIso8601String();
        }
        if (alertCopy['triggeredAt'] is DateTime) {
          alertCopy['triggeredAt'] = (alertCopy['triggeredAt'] as DateTime).toIso8601String();
        }
        return alertCopy;
      }).toList();
      
      await prefs.setString('user_${_currentUserId}_active_alerts', jsonEncode(activeForStorage));
      await prefs.setString('user_${_currentUserId}_history_alerts', jsonEncode(historyForStorage));
    } catch (e) {
      print('UserDataService: Error saving all to storage: $e');
    }
  }
  
  // Sync watchlist to backend
  Future<void> _syncWatchlistToBackend() async {
    if (_currentUserId == null || _authService.authToken == null) return;
    
    try {
      await _dio.post(
        '/user/watchlist',
        data: {'watchlist': _watchlist},
        options: Options(
          headers: {'Authorization': 'Bearer ${_authService.authToken}'},
        ),
      );
      print('UserDataService: Watchlist synced to backend');
    } catch (e) {
      print('UserDataService: Failed to sync watchlist to backend: $e');
    }
  }
  
  // Sync portfolio to backend
  Future<void> _syncPortfolioToBackend() async {
    if (_currentUserId == null || _authService.authToken == null) return;
    
    try {
      await _dio.post(
        '/user/portfolio',
        data: {'portfolio': _portfolio},
        options: Options(
          headers: {'Authorization': 'Bearer ${_authService.authToken}'},
        ),
      );
      print('UserDataService: Portfolio synced to backend');
    } catch (e) {
      print('UserDataService: Failed to sync portfolio to backend: $e');
    }
  }
  
  // Sync alerts to backend
  Future<void> _syncAlertsToBackend() async {
    if (_currentUserId == null || _authService.authToken == null) return;
    
    try {
      final activeForSync = _activeAlerts.map((alert) {
        final alertCopy = Map<String, dynamic>.from(alert);
        if (alertCopy['createdAt'] is DateTime) {
          alertCopy['createdAt'] = (alertCopy['createdAt'] as DateTime).toIso8601String();
        }
        return alertCopy;
      }).toList();
      
      final historyForSync = _historyAlerts.map((alert) {
        final alertCopy = Map<String, dynamic>.from(alert);
        if (alertCopy['createdAt'] is DateTime) {
          alertCopy['createdAt'] = (alertCopy['createdAt'] as DateTime).toIso8601String();
        }
        if (alertCopy['triggeredAt'] is DateTime) {
          alertCopy['triggeredAt'] = (alertCopy['triggeredAt'] as DateTime).toIso8601String();
        }
        return alertCopy;
      }).toList();
      
      await _dio.post(
        '/user/alerts',
        data: {
          'activeAlerts': activeForSync,
          'historyAlerts': historyForSync,
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${_authService.authToken}'},
        ),
      );
      print('UserDataService: Alerts synced to backend');
    } catch (e) {
      print('UserDataService: Failed to sync alerts to backend: $e');
    }
  }
  
  // Clean up
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}