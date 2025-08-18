import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class FeatureConfigService {
  static final FeatureConfigService _instance = FeatureConfigService._internal();
  factory FeatureConfigService() => _instance;
  FeatureConfigService._internal();

  Map<String, bool> _features = {};
  bool _isInitialized = false;
  late Dio _dio;
  
  // Admin panel API URL'i - Android emulator için 10.0.2.2 kullan
  static const String _apiBaseUrl = 'http://10.0.2.2:3002/api';
  
  // Periodic sync için timer
  Timer? _syncTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Dio client'ı başlat
      _dio = Dio(BaseOptions(
        baseUrl: _apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));

      await _loadConfiguration();
      _isInitialized = true;
      
      // Periodic sync başlat (5 saniyede bir)
      _startPeriodicSync();
      
      print('FeatureConfigService initialized successfully');
    } catch (e) {
      print('Error initializing FeatureConfigService: $e');
      _setDefaultConfiguration();
      _isInitialized = true;
    }
  }

  Future<void> _loadConfiguration() async {
    // 1. Önce admin panel API'sinden yüklemeye çalış
    if (await _loadFromAdminPanel()) {
      print('Configuration loaded from Admin Panel API');
      return;
    }

    try {
      // 2. Assets'den config dosyasını okumaya çalış
      String configString = await rootBundle.loadString('assets/zerda-config.json');
      Map<String, dynamic> config = json.decode(configString);
      
      if (config['features'] != null) {
        _features = Map<String, bool>.from(config['features']);
        print('Configuration loaded from assets');
        return;
      }
    } catch (e) {
      print('Could not load config from assets: $e');
    }

    try {
      // 3. SharedPreferences'dan yükle
      final prefs = await SharedPreferences.getInstance();
      String? savedConfig = prefs.getString('feature_config');
      
      if (savedConfig != null) {
        Map<String, dynamic> config = json.decode(savedConfig);
        if (config['features'] != null) {
          _features = Map<String, bool>.from(config['features']);
          print('Configuration loaded from SharedPreferences');
          return;
        }
      }
    } catch (e) {
      print('Could not load config from SharedPreferences: $e');
    }

    // 4. Hiçbir yerden yüklenemezse varsayılan ayarları kullan
    _setDefaultConfiguration();
  }

  // Admin panel API'sinden config yükle
  Future<bool> _loadFromAdminPanel() async {
    try {
      final response = await _dio.get('/features');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        Map<String, dynamic> features = response.data['features'];
        _features = Map<String, bool>.from(features);
        
        // Local cache'e de kaydet
        await _cacheConfiguration();
        
        return true;
      }
    } catch (e) {
      print('Could not load config from Admin Panel: $e');
    }
    return false;
  }

  // Configuration'ı local cache'e kaydet
  Future<void> _cacheConfiguration() async {
    try {
      final config = {
        'timestamp': DateTime.now().toIso8601String(),
        'features': _features,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('feature_config', json.encode(config));
    } catch (e) {
      print('Error caching configuration: $e');
    }
  }

  // Periodic sync başlat
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncWithAdminPanel();
    });
  }

  // Admin panel ile sync
  Future<void> _syncWithAdminPanel() async {
    try {
      if (!_isInitialized) return;
      
      final response = await _dio.get('/features');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        Map<String, dynamic> newFeatures = response.data['features'];
        Map<String, bool> updatedFeatures = Map<String, bool>.from(newFeatures);
        
        // Değişiklik var mı kontrol et
        bool hasChanges = false;
        for (String key in updatedFeatures.keys) {
          if (_features[key] != updatedFeatures[key]) {
            hasChanges = true;
            break;
          }
        }
        
        if (hasChanges) {
          _features = updatedFeatures;
          await _cacheConfiguration();
          print('🔄 Features updated from Admin Panel:');
          for (String key in updatedFeatures.keys) {
            if (_features[key] != updatedFeatures[key]) {
              print('   $key: ${_features[key]} → ${updatedFeatures[key]}');
            }
          }
          
          // Burada UI'a notification gönderilebilir
          _notifyFeatureChanges();
        }
      }
    } catch (e) {
      print('Error syncing with Admin Panel: $e');
    }
  }

  // Feature değişiklikleri için listener listesi
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Feature değişikliklerini bildir
  void _notifyFeatureChanges() {
    // Listeners'ları notify et
    for (final listener in _listeners) {
      listener();
    }
    print('Features have been updated remotely!');
  }

  // Sync'i durdur
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _setDefaultConfiguration() {
    _features = {
      'dashboard': true,
      'goldPrices': true,
      'converter': true,
      'alarms': true,
      'portfolio': true,
      'profile': true,
      'watchlist': true,
      'profitLossCalculator': true,
      'performanceHistory': true,
      'sarrafiyeIscilik': true,
      'gecmisKurlar': true,
    };
    print('Using default configuration');
  }

  Future<void> saveConfiguration(Map<String, bool> features) async {
    try {
      _features = features;
      
      final config = {
        'timestamp': DateTime.now().toIso8601String(),
        'features': features,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('feature_config', json.encode(config));
      
      print('Configuration saved to SharedPreferences');
    } catch (e) {
      print('Error saving configuration: $e');
    }
  }

  bool isFeatureEnabled(String featureName) {
    if (!_isInitialized) {
      print('Warning: FeatureConfigService not initialized, using default value');
      return true; // Varsayılan olarak true döndür
    }
    
    return _features[featureName] ?? true;
  }

  Map<String, bool> getAllFeatures() {
    return Map<String, bool>.from(_features);
  }

  // Specific feature getters for easy access
  bool get isDashboardEnabled => isFeatureEnabled('dashboard');
  bool get isGoldPricesEnabled => isFeatureEnabled('goldPrices');
  bool get isConverterEnabled => isFeatureEnabled('converter');
  bool get isAlarmsEnabled => isFeatureEnabled('alarms');
  bool get isPortfolioEnabled => isFeatureEnabled('portfolio');
  bool get isProfileEnabled => isFeatureEnabled('profile');
  bool get isWatchlistEnabled => isFeatureEnabled('watchlist');
  bool get isProfitLossCalculatorEnabled => isFeatureEnabled('profitLossCalculator');
  bool get isPerformanceHistoryEnabled => isFeatureEnabled('performanceHistory');
  bool get isSarrafiyeIscilikEnabled => isFeatureEnabled('sarrafiyeIscilik');
  bool get isGecmisKurlarEnabled => isFeatureEnabled('gecmisKurlar');

  // Development/Debug methods
  Future<void> enableAllFeatures() async {
    final allEnabled = Map<String, bool>.fromEntries(
      _features.keys.map((key) => MapEntry(key, true))
    );
    await saveConfiguration(allEnabled);
  }

  Future<void> disableAllFeatures() async {
    final allDisabled = Map<String, bool>.fromEntries(
      _features.keys.map((key) => MapEntry(key, false))
    );
    await saveConfiguration(allDisabled);
  }

  Future<void> resetToDefaults() async {
    _setDefaultConfiguration();
    await saveConfiguration(_features);
  }

  // Manual sync methodu
  Future<bool> syncNow() async {
    return await _loadFromAdminPanel();
  }

  // Remote config loading (for future use)
  Future<void> loadRemoteConfiguration(String url) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final config = json.decode(responseBody);
        
        if (config['features'] != null) {
          await saveConfiguration(Map<String, bool>.from(config['features']));
          print('Remote configuration loaded successfully');
        }
      }
      
      httpClient.close();
    } catch (e) {
      print('Error loading remote configuration: $e');
    }
  }

  // Analytics/Debugging
  void logFeatureUsage(String featureName) {
    if (isFeatureEnabled(featureName)) {
      print('Feature used: $featureName');
      // Buraya analytics kodu eklenebilir
    } else {
      print('Attempted to use disabled feature: $featureName');
    }
  }

  Map<String, dynamic> getConfigInfo() {
    return {
      'initialized': _isInitialized,
      'totalFeatures': _features.length,
      'enabledFeatures': _features.values.where((enabled) => enabled).length,
      'disabledFeatures': _features.values.where((enabled) => !enabled).length,
      'features': _features,
    };
  }
}