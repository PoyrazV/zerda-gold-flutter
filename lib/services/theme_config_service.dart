import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfigService {
  static final ThemeConfigService _instance = ThemeConfigService._internal();
  factory ThemeConfigService() => _instance;
  ThemeConfigService._internal();

  Map<String, dynamic> _themeConfig = {};
  bool _isInitialized = false;
  late Dio _dio;
  
  // Admin panel API URL'i
  static const String _apiBaseUrl = 'http://10.0.2.2:3009/api';
  
  // Customer ID (FeatureConfigService ile sync)
  String _customerId = 'default';
  
  // Periodic sync için timer
  Timer? _syncTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🎨 ThemeConfigService initializing...');
      print('📡 Theme API Base URL: $_apiBaseUrl');
      
      // Dio client'ı başlat
      _dio = Dio(BaseOptions(
        baseUrl: _apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));

      await _loadThemeConfiguration();
      _isInitialized = true;
      
      // Periodic sync başlat (3 saniyede bir - test için hızlandırıldı)
      _startPeriodicSync();
      
      print('✅ ThemeConfigService initialized successfully');
      print('🎨 Theme Config: $_themeConfig');
    } catch (e) {
      print('❌ Error initializing ThemeConfigService: $e');
      _setDefaultThemeConfiguration();
      _isInitialized = true;
      print('🔄 Using default theme configuration');
    }
  }

  Future<void> _loadThemeConfiguration() async {
    // 1. Önce admin panel API'sinden yüklemeye çalış
    if (await _loadFromAdminPanel()) {
      print('Theme configuration loaded from Admin Panel API');
      return;
    }

    try {
      // 2. SharedPreferences'dan yükle
      final prefs = await SharedPreferences.getInstance();
      String? savedTheme = prefs.getString('theme_config');
      
      if (savedTheme != null) {
        _themeConfig = json.decode(savedTheme);
        print('Theme configuration loaded from SharedPreferences');
        return;
      }
    } catch (e) {
      print('Could not load theme from SharedPreferences: $e');
    }

    // 3. Hiçbir yerden yüklenemezse varsayılan ayarları kullan
    _setDefaultThemeConfiguration();
  }

  // Admin panel API'sinden theme yükle
  Future<bool> _loadFromAdminPanel() async {
    try {
      // Customer ID'yi al
      await _initializeCustomerId();
      
      // Theme endpoint: /api/customers/{id}/theme
      final response = await _dio.get('/customers/$_customerId/theme');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        Map<String, dynamic> newThemeConfig = response.data['data'];
        
        // Değişiklik var mı kontrol et
        bool hasChanges = !_compareMaps(_themeConfig, newThemeConfig);
        
        _themeConfig = newThemeConfig;
        
        // Local cache'e de kaydet
        await _cacheThemeConfiguration();
        
        print('✅ Theme loaded from Multi-tenant API (Customer: $_customerId)');
        print('🎨 Theme Config: $_themeConfig');
        
        // Eğer değişiklik varsa listeners'ları bildir
        if (hasChanges) {
          _notifyThemeChanges();
          print('🔄 Theme listeners notified');
        }
        
        return true;
      }
    } catch (e) {
      print('Could not load theme from Admin Panel: $e');
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
      print('🔄 Theme Customer ID forced to: $_customerId');
    } catch (e) {
      print('Error initializing customer ID for theme, using hardcoded: $e');
      _customerId = '112e0e89-1c16-485d-acda-d0a21a24bb95';
    }
  }

  // Theme configuration'ı local cache'e kaydet
  Future<void> _cacheThemeConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_config', json.encode(_themeConfig));
    } catch (e) {
      print('Error caching theme configuration: $e');
    }
  }

  // Periodic sync başlat
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _syncWithAdminPanel();
    });
  }

  // Admin panel ile theme sync
  Future<void> _syncWithAdminPanel() async {
    try {
      if (!_isInitialized) return;
      
      final response = await _dio.get('/customers/$_customerId/theme');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        Map<String, dynamic> newThemeConfig = response.data['data'];
        
        // Değişiklik var mı kontrol et
        if (!_compareMaps(_themeConfig, newThemeConfig)) {
          _themeConfig = newThemeConfig;
          await _cacheThemeConfiguration();
          
          print('🎨 Theme updated from Admin Panel (Customer: $_customerId)');
          
          // UI'a notification gönderilebilir
          _notifyThemeChanges();
        }
      }
    } catch (e) {
      print('Error syncing theme with Admin Panel: $e');
    }
  }

  // Map karşılaştırma helper metodu
  bool _compareMaps(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    return json.encode(map1) == json.encode(map2);
  }

  void _setDefaultThemeConfiguration() {
    _themeConfig = {
      'theme_type': 'dark',
      'primary_color': '#18214F',
      'secondary_color': '#D4B896',
      'accent_color': '#FF6B6B',
      'background_color': '#FFFFFF',
      'text_color': '#000000',
      'success_color': '#4CAF50',
      'error_color': '#F44336',
      'warning_color': '#FF9800',
      'font_family': 'Inter',
      'font_size_scale': 1.0,
    };
    print('Using default theme configuration');
  }

  // Theme değişiklikleri için listener listesi
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Theme değişikliklerini bildir
  void _notifyThemeChanges() {
    for (final listener in _listeners) {
      listener();
    }
    print('Theme has been updated remotely!');
  }

  // Sync'i durdur
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // ============= THEME GETTERS =============

  // Renk getters
  Color get primaryColor => Color(int.parse(_themeConfig['primary_color']?.replaceAll('#', '0xFF') ?? '0xFF18214F'));
  Color get secondaryColor => Color(int.parse(_themeConfig['secondary_color']?.replaceAll('#', '0xFF') ?? '0xFFD4B896'));
  Color get accentColor => Color(int.parse(_themeConfig['accent_color']?.replaceAll('#', '0xFF') ?? '0xFFFF6B6B'));
  Color get backgroundColor => Color(int.parse(_themeConfig['background_color']?.replaceAll('#', '0xFF') ?? '0xFFFFFFFF'));
  Color get textColor => Color(int.parse(_themeConfig['text_color']?.replaceAll('#', '0xFF') ?? '0xFF000000'));
  Color get successColor => Color(int.parse(_themeConfig['success_color']?.replaceAll('#', '0xFF') ?? '0xFF4CAF50'));
  Color get errorColor => Color(int.parse(_themeConfig['error_color']?.replaceAll('#', '0xFF') ?? '0xFFF44336'));
  Color get warningColor => Color(int.parse(_themeConfig['warning_color']?.replaceAll('#', '0xFF') ?? '0xFFFF9800'));

  // Theme type
  bool get isDarkTheme => _themeConfig['theme_type'] == 'dark';
  String get themeType => _themeConfig['theme_type'] ?? 'dark';

  // Font configuration
  String get fontFamily => _themeConfig['font_family'] ?? 'Inter';
  double get fontSizeScale => (_themeConfig['font_size_scale'] ?? 1.0).toDouble();

  // ============= DYNAMIC THEME DATA CREATION =============

  // ThemeData oluştur
  ThemeData createThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
        onBackground: textColor,
      ),
      
      // Font theme
      textTheme: _createTextTheme(),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: isDarkTheme ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Bottom navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDarkTheme ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Text theme oluştur
  TextTheme _createTextTheme() {
    TextStyle baseStyle;
    
    try {
      switch (fontFamily.toLowerCase()) {
        case 'inter':
          baseStyle = GoogleFonts.inter();
          break;
        case 'roboto':
          baseStyle = GoogleFonts.roboto();
          break;
        case 'montserrat':
          baseStyle = GoogleFonts.montserrat();
          break;
        case 'poppins':
          baseStyle = GoogleFonts.poppins();
          break;
        case 'lato':
          baseStyle = GoogleFonts.lato();
          break;
        default:
          baseStyle = GoogleFonts.inter();
      }
    } catch (e) {
      print('Error loading font $fontFamily, using Inter: $e');
      baseStyle = GoogleFonts.inter();
    }

    return TextTheme(
      displayLarge: baseStyle.copyWith(
        fontSize: 32 * fontSizeScale,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: baseStyle.copyWith(
        fontSize: 28 * fontSizeScale,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: baseStyle.copyWith(
        fontSize: 24 * fontSizeScale,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineLarge: baseStyle.copyWith(
        fontSize: 22 * fontSizeScale,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: baseStyle.copyWith(
        fontSize: 20 * fontSizeScale,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: baseStyle.copyWith(
        fontSize: 18 * fontSizeScale,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: baseStyle.copyWith(
        fontSize: 16 * fontSizeScale,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: baseStyle.copyWith(
        fontSize: 14 * fontSizeScale,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: baseStyle.copyWith(
        fontSize: 12 * fontSizeScale,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: baseStyle.copyWith(
        fontSize: 16 * fontSizeScale,
        color: textColor,
      ),
      bodyMedium: baseStyle.copyWith(
        fontSize: 14 * fontSizeScale,
        color: textColor,
      ),
      bodySmall: baseStyle.copyWith(
        fontSize: 12 * fontSizeScale,
        color: textColor,
      ),
    );
  }

  // ============= UTILITY METHODS =============

  // Customer ID değiştirme
  Future<void> setCustomerId(String customerId) async {
    if (customerId != _customerId) {
      _customerId = customerId;
      
      // Customer ID'yi kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_id', customerId);
      
      // Yeni customer için theme'ı yükle
      await _loadFromAdminPanel();
      _notifyThemeChanges();
      
      print('✅ Theme customer changed to: $customerId');
    }
  }

  // Aktif customer ID'yi al
  String get customerId => _customerId;

  // Manual sync methodu
  Future<bool> syncNow() async {
    return await _loadFromAdminPanel();
  }

  // Theme bilgilerini al
  Map<String, dynamic> getThemeInfo() {
    return {
      'initialized': _isInitialized,
      'customerId': _customerId,
      'themeType': themeType,
      'fontFamily': fontFamily,
      'fontSizeScale': fontSizeScale,
      'primaryColor': _themeConfig['primary_color'],
      'secondaryColor': _themeConfig['secondary_color'],
      'config': _themeConfig,
    };
  }

  // Reset tema
  Future<void> resetToDefaults() async {
    _setDefaultThemeConfiguration();
    await _cacheThemeConfiguration();
    _notifyThemeChanges();
  }

  // Tema güncelle (local)
  Future<void> updateThemeConfig(Map<String, dynamic> newConfig) async {
    _themeConfig = {..._themeConfig, ...newConfig};
    await _cacheThemeConfiguration();
    _notifyThemeChanges();
  }
}