import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme_config_service.dart';

class FeatureConfigService {
  static final FeatureConfigService _instance = FeatureConfigService._internal();
  factory FeatureConfigService() => _instance;
  FeatureConfigService._internal();

  Map<String, bool> _features = {};
  bool _isInitialized = false;
  late Dio _dio;
  
  // Admin panel API URL'i - Yeni gelişmiş backend (port 3009)
  static const String _apiBaseUrl = 'http://10.0.2.2:3009/api';
  static const String _wsBaseUrl = 'ws://10.0.2.2:3009';
  
  // Multi-tenant customer ID (varsayılan olarak demo customer)
  String _customerId = 'default';
  
  // Periodic sync için timer
  Timer? _syncTimer;
  
  // WebSocket connection
  WebSocketChannel? _wsChannel;
  bool _wsConnected = false;
  int _wsRetryCount = 0;
  Timer? _wsRetryTimer;
  static const int _maxWsRetries = 5;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 FeatureConfigService initializing...');
      print('📡 API Base URL: $_apiBaseUrl');
      
      // Dio client'ı başlat - timeout sürelerini artır
      _dio = Dio(BaseOptions(
        baseUrl: _apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
      ));

      await _loadConfiguration();
      _isInitialized = true;
      
      // Periodic sync başlat (30 saniyede bir)
      _startPeriodicSync();
      
      // WebSocket bağlantısını devre dışı bırak - sadece HTTP sync kullan
      // _initializeWebSocket().catchError((error) {
      //   print('⚠️ WebSocket initialization failed: $error');
      //   print('💡 Continuing with HTTP-only sync...');
      // });
      print('💡 Using HTTP-only sync mode (WebSocket disabled)');
      
      print('✅ FeatureConfigService initialized successfully');
      print('📊 Loaded ${_features.length} features: $_features');
    } catch (e) {
      print('❌ Error initializing FeatureConfigService: $e');
      _setDefaultConfiguration();
      _isInitialized = true;
      print('🔄 Using default configuration: $_features');
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

  // Admin panel API'sinden config yükle (Yeni multi-tenant API)
  Future<bool> _loadFromAdminPanel() async {
    try {
      print('🌐 Loading from Admin Panel API...');
      
      // İlk olarak customer ID'yi belirle
      await _initializeCustomerId();
      print('👤 Using Customer ID: $_customerId');
      
      // Yeni endpoint: /api/customers/{id}/features
      final url = '/customers/$_customerId/features';
      print('📞 Calling: $_apiBaseUrl$url');
      
      final response = await _dio.get(url);
      
      print('📡 Response Status: ${response.statusCode}');
      print('📋 Response Data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        Map<String, dynamic> features = response.data['features'];
        _features = Map<String, bool>.from(features);
        
        // Local cache'e de kaydet
        await _cacheConfiguration();
        
        print('✅ Features loaded from Multi-tenant API (Customer: $_customerId)');
        print('📊 Features: $_features');
        return true;
      } else {
        print('⚠️ API responded with error: ${response.data}');
      }
    } catch (e) {
      print('❌ Could not load config from Admin Panel: $e');
      print('🔄 Trying legacy API fallback...');
      // Fallback: Eski API'yi dene
      return await _loadFromLegacyAPI();
    }
    return false;
  }
  
  // Customer ID'yi initialize et
  Future<void> _initializeCustomerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Force new customer ID - eski cache'i temizle
      _customerId = '112e0e89-1c16-485d-acda-d0a21a24bb95';
      await prefs.setString('customer_id', _customerId);
      print('🔄 Customer ID forced to: $_customerId');
    } catch (e) {
      print('Error initializing customer ID, using hardcoded: $e');
      _customerId = '112e0e89-1c16-485d-acda-d0a21a24bb95';
    }
  }
  
  // Eski API ile uyumluluk (Backwards compatibility)
  Future<bool> _loadFromLegacyAPI() async {
    try {
      final response = await _dio.get('/features');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        Map<String, dynamic> features = response.data['features'];
        _features = Map<String, bool>.from(features);
        
        await _cacheConfiguration();
        print('✅ Features loaded from Legacy API');
        return true;
      }
    } catch (e) {
      print('Legacy API also failed: $e');
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

  // Periodic sync başlat - daha uzun interval ile
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Sync'i try-catch ile sar ki hata durumunda uygulama çökmesin
      try {
        _syncWithAdminPanel().catchError((error) {
          // Sessizce hataları yoksay, log yazma
        });
      } catch (e) {
        // Sync hatalarını sessizce yoksay
      }
    });
  }

  // Admin panel ile sync (Yeni multi-tenant API)
  Future<void> _syncWithAdminPanel() async {
    try {
      if (!_isInitialized) return;
      
      // Yeni endpoint kullan
      final response = await _dio.get('/customers/$_customerId/features');
      
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
          Map<String, bool> oldFeatures = Map<String, bool>.from(_features);
          _features = updatedFeatures;
          await _cacheConfiguration();
          
          print('🔄 Features updated from Admin Panel (Customer: $_customerId):');
          for (String key in updatedFeatures.keys) {
            if (oldFeatures[key] != updatedFeatures[key]) {
              print('   $key: ${oldFeatures[key]} → ${updatedFeatures[key]}');
            }
          }
          
          // UI'a notification gönderilebilir
          _notifyFeatureChanges();
        }
      }
    } catch (e) {
      // Fallback: eski API'yi dene
      try {
        final response = await _dio.get('/features');
        if (response.statusCode == 200 && response.data['success'] == true) {
          Map<String, dynamic> newFeatures = response.data['features'];
          Map<String, bool> updatedFeatures = Map<String, bool>.from(newFeatures);
          
          if (!_compareMaps(_features, updatedFeatures)) {
            _features = updatedFeatures;
            await _cacheConfiguration();
            _notifyFeatureChanges();
            print('🔄 Features synced via Legacy API');
          }
        }
      } catch (legacyError) {
        print('Error syncing with Admin Panel (both APIs failed): $e, $legacyError');
      }
    }
  }
  
  // Map karşılaştırma helper metodu
  bool _compareMaps(Map<String, bool> map1, Map<String, bool> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
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
    _closeWebSocket();
  }

  // WebSocket bağlantısını başlat (with retry and timeout handling)
  Future<void> _initializeWebSocket() async {
    // Cancel any existing retry timer
    _wsRetryTimer?.cancel();
    
    // Don't retry if we've exceeded max retries
    if (_wsRetryCount >= _maxWsRetries) {
      print('⚠️ WebSocket max retries ($_maxWsRetries) exceeded - disabling WebSocket');
      return;
    }
    
    try {
      print('🔌 Initializing WebSocket connection... (attempt ${_wsRetryCount + 1}/$_maxWsRetries)');
      
      // Close existing connection if any
      await _closeWebSocket();
      
      final wsUrl = Uri.parse('$_wsBaseUrl/socket.io/?EIO=4&transport=websocket');
      print('🌐 WebSocket URL: $wsUrl');
      
      _wsChannel = WebSocketChannel.connect(wsUrl);
      
      // Add timeout for connection establishment
      bool connectionEstablished = false;
      Timer connectionTimeout = Timer(const Duration(seconds: 10), () {
        if (!connectionEstablished) {
          print('⏰ WebSocket connection timeout');
          _handleWebSocketError('Connection timeout');
        }
      });
      
      // WebSocket mesajlarını dinle
      _wsChannel!.stream.listen(
        (data) {
          if (!connectionEstablished) {
            connectionEstablished = true;
            connectionTimeout.cancel();
            _wsConnected = true;
            _wsRetryCount = 0; // Reset retry count on successful connection
            print('✅ WebSocket connected successfully');
            
            // Customer room'a katıl
            try {
              _wsChannel!.sink.add('42["join_customer","$_customerId"]');
            } catch (e) {
              print('❌ Failed to join customer room: $e');
            }
          }
          
          print('📨 WebSocket received: $data');
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          connectionTimeout.cancel();
          connectionEstablished = false;
          print('❌ WebSocket error: $error');
          _handleWebSocketError(error.toString());
        },
        onDone: () {
          connectionTimeout.cancel();
          connectionEstablished = false;
          print('📤 WebSocket connection closed');
          _wsConnected = false;
          
          // Auto-reconnect if not exceeded retry limit
          if (_wsRetryCount < _maxWsRetries) {
            _scheduleWebSocketRetry();
          }
        },
      );
      
    } catch (e) {
      print('❌ Failed to initialize WebSocket: $e');
      _handleWebSocketError(e.toString());
    }
  }
  
  // WebSocket error handling with retry logic
  void _handleWebSocketError(String error) {
    _wsConnected = false;
    _wsRetryCount++;
    
    if (_wsRetryCount <= _maxWsRetries) {
      _scheduleWebSocketRetry();
    } else {
      print('⚠️ WebSocket permanently disabled after $_maxWsRetries failed attempts');
      print('💡 App will continue to work with periodic HTTP sync only');
    }
  }
  
  // Schedule WebSocket retry with exponential backoff
  void _scheduleWebSocketRetry() {
    final retryDelay = Duration(seconds: 5 + (_wsRetryCount * 5)); // 5s, 10s, 15s, etc.
    print('🔄 Scheduling WebSocket retry in ${retryDelay.inSeconds}s... (attempt ${_wsRetryCount + 1}/$_maxWsRetries)');
    
    _wsRetryTimer = Timer(retryDelay, () {
      _initializeWebSocket();
    });
  }
  
  // Close WebSocket connection gracefully
  Future<void> _closeWebSocket() async {
    try {
      _wsRetryTimer?.cancel();
      await _wsChannel?.sink.close();
      _wsChannel = null;
      _wsConnected = false;
    } catch (e) {
      print('Error closing WebSocket: $e');
    }
  }

  // WebSocket mesajlarını işle
  void _handleWebSocketMessage(dynamic data) {
    try {
      final String message = data.toString();
      
      // Socket.io mesaj formatını parse et
      if (message.startsWith('42')) {
        final jsonStr = message.substring(2);
        final parsed = json.decode(jsonStr);
        
        if (parsed is List && parsed.length >= 2) {
          final eventName = parsed[0];
          final eventData = parsed[1];
          
          if (eventName == 'feature_updated') {
            print('🔄 Feature update received: $eventData');
            _handleFeatureUpdate(eventData);
          } else if (eventName == 'theme_updated') {
            print('🎨 Theme update received: $eventData');
            _handleThemeUpdate(eventData);
          }
        }
      }
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
    }
  }

  // Feature güncellemelerini işle
  void _handleFeatureUpdate(Map<String, dynamic> data) {
    try {
      final featureName = data['featureName'] as String?;
      final enabled = data['enabled'] as bool?;
      
      if (featureName != null && enabled != null) {
        _features[featureName] = enabled;
        _cacheConfiguration();
        _notifyFeatureChanges();
        
        print('🔄 Feature updated via WebSocket: $featureName = $enabled');
      }
    } catch (e) {
      print('❌ Error handling feature update: $e');
    }
  }

  // Theme güncellemelerini işle  
  void _handleThemeUpdate(Map<String, dynamic> data) {
    print('🎨 Theme update received, notifying ThemeConfigService');
    
    // ThemeConfigService'a bildir
    try {
      ThemeConfigService().syncNow();
      print('✅ ThemeConfigService sync triggered');
    } catch (e) {
      print('❌ Error triggering theme sync: $e');
    }
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
      'adminPanel': true,
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
  bool get isAdminPanelEnabled => isFeatureEnabled('adminPanel');

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
  
  // Customer ID değiştirme (Multi-tenant destek)
  Future<void> setCustomerId(String customerId) async {
    if (customerId != _customerId) {
      _customerId = customerId;
      
      // Customer ID'yi kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_id', customerId);
      
      // Yeni customer için feature'ları yükle
      await _loadFromAdminPanel();
      _notifyFeatureChanges();
      
      print('✅ Customer changed to: $customerId');
    }
  }
  
  // Aktif customer ID'yi al
  String get customerId => _customerId;

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