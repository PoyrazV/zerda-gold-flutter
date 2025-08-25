import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'notification_service.dart';

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
    
    // Verify token if exists
    if (_authToken != null) {
      await _verifyToken();
    }
    
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
      
      // Call backend logout API
      if (_authToken != null) {
        await _dio.post(
          '/auth/logout',
          data: {'fcm_token': fcmToken},
          options: Options(
            headers: {'Authorization': 'Bearer $_authToken'},
          ),
        );
      }
      
      // Update FCM token to mark as guest (remove user info)
      if (fcmToken != null) {
        await Dio().post(
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
        print('✅ FCM token marked as guest after logout');
      }
    } catch (e) {
      print('Logout API error: $e');
    }
    
    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _userProfileImage = null;
    _userId = null;
    _authToken = null;
    
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
        }
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
  
  // Get device ID
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      // Generate a unique device ID
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
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
}