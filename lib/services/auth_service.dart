import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'notification_service.dart';
import 'user_data_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // API configuration
  static const String _apiBaseUrl = 'http://10.0.2.2:3009/api/mobile';
  late Dio _dio;
  
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userProfileImage;
  String? _userId;
  String? _authToken;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userProfileImage => _userProfileImage;
  String? get userId => _userId;
  String? get authToken => _authToken;

  // Initialize auth state from SharedPreferences
  Future<void> initialize() async {
    print('🔐 AuthService: Initializing...');
    
    // Initialize Dio
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userEmail = prefs.getString('userEmail');
    _userName = prefs.getString('userName');
    _userProfileImage = prefs.getString('userProfileImage');
    _userId = prefs.getString('userId');
    _authToken = prefs.getString('authToken');
    
    print('🔐 AuthService: Loaded from storage - isLoggedIn: $_isLoggedIn, userId: $_userId, email: $_userEmail');
    
    // Verify token if exists
    if (_authToken != null) {
      print('🔐 AuthService: Verifying token...');
      await _verifyToken();
    }
    
    print('🔐 AuthService: Initialization complete - isLoggedIn: $_isLoggedIn, userId: $_userId');
    notifyListeners();
  }
  
  // Verify token validity
  Future<void> _verifyToken() async {
    try {
      final response = await _dio.get(
        '/auth/verify',
        options: Options(
          headers: {'Authorization': 'Bearer $_authToken'},
        ),
      );
      
      if (response.data['success'] == true) {
        final user = response.data['data']['user'];
        _userId = user['id'];
        _userEmail = user['email'];
        _userName = user['full_name'];
        _userProfileImage = user['profile_image'];
        _isLoggedIn = true;
      } else {
        await logout();
      }
    } catch (e) {
      print('Token verification failed: $e');
      await logout();
    }
  }

  // Login method
  Future<bool> login({
    required String email,
    required String password,
    String? userName,
    String? profileImage,
  }) async {
    try {
      // Get FCM token and device info
      final notificationService = NotificationService();
      final fcmToken = await notificationService.getToken();
      final deviceId = await _getDeviceId();
      
      // Call backend login API
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'fcm_token': fcmToken,
        'device_id': deviceId,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      
      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final user = userData['user'];
        
        // Save auth data
        _authToken = userData['token'];
        _userId = user['id'];
        _userEmail = user['email'];
        _userName = user['full_name'] ?? userName ?? email.split('@')[0];
        _userProfileImage = user['profile_image'] ?? profileImage;
        _isLoggedIn = true;
        
        print('🔐 AuthService: Login successful - userId: $_userId, email: $_userEmail');
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('authToken', _authToken!);
        await prefs.setString('userId', _userId!);
        await prefs.setString('userEmail', _userEmail!);
        await prefs.setString('userName', _userName!);
        if (_userProfileImage != null) {
          await prefs.setString('userProfileImage', _userProfileImage!);
        }
        
        // Update FCM token with user info
        await _updateFCMToken();
        
        // Force WebSocket reconnection with auth info
        _forceWebSocketReconnection();
        
        // Wait for UserDataService to load user data
        print('🔄 AuthService: Waiting for UserDataService to load user data...');
        final userDataService = UserDataService();
        await userDataService.loadUserData(_userId);
        print('✅ AuthService: UserDataService data loaded successfully');
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      // Get FCM token to update it as guest
      final notificationService = NotificationService();
      final fcmToken = await notificationService.getToken();
      final deviceId = await _getDeviceId();
      
      // Store previous user info for logging
      final previousUser = _userEmail;
      final previousUserId = _userId;
      
      print('🔄 Starting logout process...');
      print('   Previous user: $previousUser (ID: $previousUserId)');
      print('   Device ID: $deviceId');
      
      // Clear UserDataService before clearing auth data
      print('🧹 Clearing UserDataService data...');
      await UserDataService().clearCurrentUserData();
      
      // Call backend logout API
      if (_authToken != null) {
        try {
          await _dio.post(
            '/auth/logout',
            data: {'fcm_token': fcmToken},
            options: Options(
              headers: {'Authorization': 'Bearer $_authToken'},
            ),
          );
          print('✅ Backend logout successful');
        } catch (e) {
          print('⚠️ Backend logout failed (continuing): $e');
        }
      }
      
      // Update FCM token to mark as guest (remove user info)
      if (fcmToken != null) {
        print('🔄 Updating FCM token to guest mode...');
        print('   Token: ${fcmToken.substring(0, 30)}...');
        
        try {
          final response = await Dio().post(
            'http://10.0.2.2:3009/api/mobile/register-fcm-token',
            data: {
              'customerId': 'ffeee61a-8497-4c70-857e-c8f0efb13a2a',
              'fcmToken': fcmToken,
              'deviceId': deviceId,
              'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
              'userId': null,  // Explicitly set to null to mark as guest
              'userEmail': null,  // Explicitly set to null to mark as guest
            },
          );
          
          if (response.data['success'] == true) {
            print('✅ FCM token successfully marked as guest');
            print('   Device ID preserved: $deviceId');
            print('   New status: Guest (is_authenticated = 0)');
            print('   Previous user cleared: $previousUser → null');
          } else {
            print('⚠️ FCM token update response not successful: ${response.data}');
          }
        } catch (e) {
          print('❌ Failed to update FCM token to guest: $e');
          // Try once more with a small delay
          await Future.delayed(Duration(seconds: 1));
          try {
            await Dio().post(
              'http://10.0.2.2:3009/api/mobile/register-fcm-token',
              data: {
                'customerId': 'ffeee61a-8497-4c70-857e-c8f0efb13a2a',
                'fcmToken': fcmToken,
                'deviceId': deviceId,
                'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
                'userId': null,
                'userEmail': null,
              },
            );
            print('✅ FCM token updated on retry');
          } catch (retryError) {
            print('❌ FCM token update failed on retry: $retryError');
          }
        }
      } else {
        print('⚠️ No FCM token available to update');
      }
    } catch (e) {
      print('❌ Logout process error: $e');
    }
    
    // Clear ONLY auth-related data (preserve user data like alarms, watchlist, etc.)
    final prefs = await SharedPreferences.getInstance();
    
    // Remove only authentication keys
    await prefs.remove('isLoggedIn');
    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
    await prefs.remove('userProfileImage');
    // Note: device_id is preserved for notifications continuity
    // Note: user data (alarms, watchlist, portfolio) is preserved for multi-user support
    
    print('✅ Auth data cleared (user data preserved)');
    
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _userProfileImage = null;
    _userId = null;
    _authToken = null;
    
    // Force WebSocket reconnection as guest
    _forceWebSocketReconnection();
    
    notifyListeners();
  }
  
  // Register method
  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      // Get FCM token and device info
      final notificationService = NotificationService();
      final fcmToken = await notificationService.getToken();
      final deviceId = await _getDeviceId();
      
      // Call backend register API
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName ?? email.split('@')[0],
        'fcm_token': fcmToken,
        'device_id': deviceId,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      
      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final user = userData['user'];
        
        // Save auth data
        _authToken = userData['token'];
        _userId = user['id'];
        _userEmail = user['email'];
        _userName = user['full_name'];
        _userProfileImage = user['profile_image'];
        _isLoggedIn = true;
        
        print('🔐 AuthService: Register successful - userId: $_userId, email: $_userEmail');
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('authToken', _authToken!);
        await prefs.setString('userId', _userId!);
        await prefs.setString('userEmail', _userEmail!);
        await prefs.setString('userName', _userName!);
        if (_userProfileImage != null) {
          await prefs.setString('userProfileImage', _userProfileImage!);
        }
        
        // Update FCM token with user info
        await _updateFCMToken();
        
        // Force WebSocket reconnection with auth info
        _forceWebSocketReconnection();
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Register error: $e');
      // Re-throw the error so the UI can handle it appropriately
      if (e.toString().contains('409')) {
        throw Exception('Email already registered');
      } else if (e.toString().contains('DioException')) {
        throw Exception('Network connection error');
      }
      throw Exception('Registration failed: $e');
    }
  }
  
  // Update FCM token with user info
  Future<void> _updateFCMToken() async {
    try {
      final notificationService = NotificationService();
      final fcmToken = await notificationService.getToken();
      final deviceId = await _getDeviceId();
      
      if (fcmToken != null) {
        // Use the full API path instead of relative path
        final response = await Dio().post(
          'http://10.0.2.2:3009/api/mobile/register-fcm-token',
          data: {
            'customerId': 'ffeee61a-8497-4c70-857e-c8f0efb13a2a', // Default customer
            'fcmToken': fcmToken,
            'deviceId': deviceId,
            'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            'userId': _userId,
            'userEmail': _userEmail,
          },
        );
        
        if (response.data['success'] == true) {
          print('✅ FCM token updated with user info');
          print('   User: $_userEmail');
          print('   Device: $deviceId');
          print('   Token: ${fcmToken?.substring(0, 20)}...');
        } else {
          print('❌ FCM token update failed: ${response.data}');
        }
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
  
  // Get device ID - more robust implementation
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      // Generate a unique device ID using multiple factors
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = timestamp % 10000;
      deviceId = 'dev_${timestamp}_$random';
      await prefs.setString('device_id', deviceId);
      print('🔑 Generated new device ID: $deviceId');
    } else if (!deviceId.startsWith('dev_')) {
      // Migrate old format to new format
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = timestamp % 10000;
      deviceId = 'dev_${deviceId}_$random';
      await prefs.setString('device_id', deviceId);
      print('🔄 Migrated device ID to new format: $deviceId');
    }
    
    return deviceId;
  }

  // Mock login for testing
  Future<void> mockLogin() async {
    await login(
      email: 'demo@zerda.com',
      password: 'demo123',
      userName: 'Demo User',
    );
  }
  
  // Force WebSocket reconnection with current auth state
  void _forceWebSocketReconnection() {
    try {
      // Import and call the NotificationWebSocketService
      // We'll do this dynamically to avoid circular dependencies
      print('🔄 Forcing WebSocket reconnection after auth state change...');
      
      // This will be called from NotificationService which manages the WebSocket
      // We'll trigger this through notifyListeners which NotificationService listens to
    } catch (e) {
      print('Error forcing WebSocket reconnection: $e');
    }
  }
}