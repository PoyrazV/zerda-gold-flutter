import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_websocket_service.dart';
import 'auth_service.dart';

// Top-level function for background message handling (called from other files)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.handleBackgroundMessage(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  // Static method for handling background messages
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    
    // Extract title and body from notification or data payload
    final String title = message.notification?.title ?? 
                        message.data['title'] ?? 
                        'Zerda Gold';
    final String body = message.notification?.body ?? 
                       message.data['body'] ?? 
                       'Yeni bildirim';
    
    print('🔔 Background message received');
    print('   Title: $title');
    print('   Body: $body');
    print('   Has notification field: ${message.notification != null}');
    print('   Type: ${message.data['type']}');
    
    // Only show local notification if Firebase didn't already show one
    // (Firebase auto-shows if notification field exists)
    if (message.notification == null) {
      // Initialize local notifications plugin for background
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
          FlutterLocalNotificationsPlugin();
      
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'zerda_notifications',
        'Zerda Notifications',
        description: 'Zerda Gold notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      
      // Initialize with Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      
      // Create Android notification channel
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      // Create notification details with wake lock
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'zerda_notifications',
        'Zerda Notifications',
        channelDescription: 'Zerda Gold notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true, // Wake up device
        category: AndroidNotificationCategory.message,
      );
      
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      
      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        details,
        payload: message.data.toString(),
      );
      
      print('✅ Local notification shown in background');
    } else {
      print('ℹ️ Skipping local notification (Firebase will show it)');
    }
    
    // Always save to SharedPreferences for later retrieval
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('background_notifications') ?? [];
      notifications.add(jsonEncode({
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'type': message.data['type'] ?? 'info',
        'timestamp': DateTime.now().toIso8601String(),
        'data': message.data,
      }));
      await prefs.setStringList('background_notifications', notifications);
      print('📬 Stored background notification for later processing');
    } catch (e) {
      print('❌ Error saving background notification: $e');
    }
  }

  // Admin panel HTTP URL
  static const String _baseUrl = 'http://10.0.2.2:3009';
  static const String _customerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  // Flutter Local Notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  
  // Firebase Cloud Messaging
  FirebaseMessaging? _firebaseMessaging;
  String? _fcmToken;
  bool _fcmInitialized = false;
  
  // Notification listeners
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];
  
  // Son bildirimleri sakla
  final List<Map<String, dynamic>> _recentNotifications = [];
  
  // WebSocket service for real-time notifications
  NotificationWebSocketService? _webSocketService;
  StreamSubscription? _webSocketSubscription;
  AuthService? _authService;
  
  // Public getters
  String? get fcmToken => _fcmToken;
  
  // Get token method for external use
  Future<String?> getToken() async {
    if (_fcmToken != null) {
      return _fcmToken;
    }
    
    // Try to get token if Firebase is initialized
    if (_fcmInitialized && _firebaseMessaging != null) {
      try {
        _fcmToken = await _firebaseMessaging!.getToken();
        return _fcmToken;
      } catch (e) {
        print('Error getting FCM token: $e');
      }
    }
    
    return null;
  }

  Future<void> initialize() async {
    print('🔔 NotificationService initializing...');
    
    // Initialize Firebase and FCM first
    await _initializeFirebase();
    
    // Initialize local notifications
    await _initializeNotifications();
    
    // Initialize WebSocket service for real-time notifications
    await _initializeWebSocketService();
    
    // Check for background notifications
    await _checkBackgroundNotifications();
    
    print('🔔 NotificationService fully initialized with FCM and WebSocket support');
  }

  Future<void> _initializeFirebase() async {
    if (_fcmInitialized) return;
    
    try {
      print('🔥 Initializing Firebase...');
      
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        print('🔥 Firebase Core initialized');
      }
      
      // Initialize Firebase Messaging
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('🔥 FCM Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _firebaseMessaging!.getToken();
        print('🔥 FCM Token: $_fcmToken');
        
        // Save token to server
        await _registerFCMToken(_fcmToken!);
        
        // Listen for token refresh
        _firebaseMessaging!.onTokenRefresh.listen(_handleTokenRefresh);
        
        // Set up message handlers
        await _setupFCMHandlers();
        
        _fcmInitialized = true;
        print('🔥 Firebase Cloud Messaging initialized successfully');
      } else {
        print('⚠️ FCM permission denied');
      }
    } catch (e) {
      print('❌ Failed to initialize Firebase: $e');
      // Don't block the app if FCM fails - fallback to HTTP polling
    }
  }

  Future<void> _initializeWebSocketService() async {
    try {
      print('🔌 Initializing NotificationWebSocketService...');
      
      // Initialize auth service reference
      _authService = AuthService();
      
      // Initialize WebSocket service
      _webSocketService = NotificationWebSocketService();
      await _webSocketService!.initialize();
      
      // Listen to WebSocket notifications
      _webSocketSubscription = _webSocketService!.notificationStream.listen((notificationData) {
        print('📨 WebSocket notification received in NotificationService');
        _handleNotificationReceived(notificationData);
      });
      
      // Listen to auth state changes to force WebSocket reconnection
      _authService!.addListener(_onAuthStateChanged);
      
      print('✅ NotificationWebSocketService initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize NotificationWebSocketService: $e');
      // Continue without WebSocket - FCM will still work
    }
  }
  
  void _onAuthStateChanged() {
    print('🔄 Auth state changed in NotificationService, forcing WebSocket reconnection...');
    _webSocketService?.forceReconnect();
  }
  
  Future<void> _checkBackgroundNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('background_notifications') ?? [];
      
      if (notifications.isNotEmpty) {
        print('📬 Found ${notifications.length} background notifications');
        
        for (final notificationJson in notifications) {
          try {
            final notification = jsonDecode(notificationJson);
            print('   - ${notification['title']} at ${notification['timestamp']}');
            
            // Add to recent notifications
            _recentNotifications.insert(0, notification);
            
            // Notify listeners
            for (final listener in _notificationListeners) {
              try {
                listener(notification);
              } catch (e) {
                print('❌ Error in notification listener: $e');
              }
            }
          } catch (e) {
            print('❌ Error parsing background notification: $e');
          }
        }
        
        // Clear background notifications after processing
        await prefs.remove('background_notifications');
        print('✅ Background notifications processed and cleared');
      }
    } catch (e) {
      print('❌ Error checking background notifications: $e');
    }
  }

  // Manual refresh method for testing or fallback
  Future<void> manualRefresh() async {
    try {
      print('🔄 Manual refresh requested');
      // This can be used for testing or as a fallback
      // But primary notifications come through FCM
    } catch (e) {
      print('❌ Manual refresh error: $e');
    }
  }
  void _handleNotificationReceived(Map<String, dynamic> notificationData) {
    // Add to recent notifications
    _recentNotifications.insert(0, {
      ...notificationData,
      'received_at': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 50 notifications
    if (_recentNotifications.length > 50) {
      _recentNotifications.removeRange(50, _recentNotifications.length);
    }
    
    // Show local notification
    _showLocalNotification(notificationData);
    
    // Notify listeners
    for (final listener in _notificationListeners) {
      try {
        listener(notificationData);
      } catch (e) {
        print('❌ Error in notification listener: $e');
      }
    }
  }

  void _showLocalNotification(Map<String, dynamic> data) {
    print('📱 Showing push notification:');
    print('   Title: ${data['title']}');
    print('   Message: ${data['message']}');
    print('   Type: ${data['type']}');
    
    // Show actual system push notification
    _showSystemNotification(data);
  }

  void _showInAppNotification(Map<String, dynamic> data) {
    // Find the current context and show snackbar
    // This is a simple implementation - in production use overlay or notification plugin
    final navigatorKey = _getNavigatorKey();
    if (navigatorKey?.currentContext != null) {
      final context = navigatorKey!.currentContext!;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getNotificationIcon(data['type']),
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Bildirim',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (data['message'] != null)
                      Text(
                        data['message'],
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: _getNotificationColor(data['type']),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  GlobalKey<NavigatorState>? _getNavigatorKey() {
    // This should be provided by your main app
    // For now, we'll try to get it from the widget tree
    try {
      return _navigatorKey;
    } catch (e) {
      return null;
    }
  }

  // This should be set by your main app
  static GlobalKey<NavigatorState>? _navigatorKey;
  
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }


  // Public API
  void addNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.add(listener);
  }

  void removeNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.remove(listener);
  }

  List<Map<String, dynamic>> get recentNotifications => List.from(_recentNotifications);

  bool get isConnected => _fcmInitialized; // Now using FCM connection status

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      // Request notification permissions
      final permissionStatus = await Permission.notification.request();
      print('📋 Notification permission status: $permissionStatus');

      // Initialize the plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'zerda_notifications',
        'Zerda Bildirimler',
        description: 'Zerda Gold uygulaması bildirimleri',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _notificationsInitialized = true;
      print('🔔 Local notifications initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize notifications: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('🔔 Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap if needed
  }

  Future<void> _showSystemNotification(Map<String, dynamic> data) async {
    if (!_notificationsInitialized) {
      print('⚠️ Notifications not initialized, falling back to in-app');
      _showInAppNotification(data);
      return;
    }

    try {
      final title = data['title'] ?? 'Zerda Gold';
      final message = data['message'] ?? 'Yeni bildirim';
      final type = data['type'] ?? 'info';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'zerda_notifications',
            'Zerda Bildirimler',
            channelDescription: 'Zerda Gold uygulaması bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'Zerda Gold',
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        message,
        platformChannelSpecifics,
        payload: data['id']?.toString(),
      );

      print('✅ System notification sent successfully');
    } catch (e) {
      print('❌ Failed to show system notification: $e');
      // Fallback to in-app notification
      _showInAppNotification(data);
    }
  }

  Future<void> _setupFCMHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Handle messages when app is completely terminated
    RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedAppMessage(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('🔥 FCM foreground message received');
    print('   Has notification field: ${message.notification != null}');
    
    // Convert FCM message to our notification format
    final notificationData = _fcmMessageToNotificationData(message);
    
    // In foreground, always show local notification
    // (Firebase doesn't auto-show in foreground)
    _handleNotificationReceived(notificationData);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('🔥 FCM background message opened: ${message.notification?.title}');
    
    // Convert and handle notification
    final notificationData = _fcmMessageToNotificationData(message);
    _handleNotificationReceived(notificationData);
  }

  void _handleTerminatedAppMessage(RemoteMessage message) {
    print('🔥 FCM terminated app message: ${message.notification?.title}');
    
    // Convert and handle notification
    final notificationData = _fcmMessageToNotificationData(message);
    _handleNotificationReceived(notificationData);
  }

  Map<String, dynamic> _fcmMessageToNotificationData(RemoteMessage message) {
    // Extract from BOTH notification and data payloads
    // Prefer notification field if available (sent when app is killed)
    final String title = message.notification?.title ?? 
                        message.data['title'] ?? 
                        'Zerda Gold';
    final String body = message.notification?.body ?? 
                       message.data['body'] ?? 
                       'Yeni bildirim';
    
    print('📨 Processing FCM message:');
    print('   Has notification: ${message.notification != null}');
    print('   Title: $title');
    print('   Body: $body');
    print('   Data: ${message.data}');
    
    return {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': body,
      'type': message.data['type'] ?? 'info',
      'timestamp': DateTime.now().toIso8601String(),
      'data': message.data,
      'hasNotificationField': message.notification != null,
    };
  }

  Future<void> _registerFCMToken(String token) async {
    try {
      // Get device ID for consistent token management
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');
      
      if (deviceId == null) {
        // Generate device ID if not exists
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = timestamp % 10000;
        deviceId = 'dev_${timestamp}_$random';
        await prefs.setString('device_id', deviceId);
        print('🔑 Generated new device ID for FCM: $deviceId');
      } else if (!deviceId.startsWith('dev_')) {
        // Migrate old format to new format
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = timestamp % 10000;
        deviceId = 'dev_${deviceId}_$random';
        await prefs.setString('device_id', deviceId);
        print('🔄 Migrated device ID to new format for FCM: $deviceId');
      }
      
      // Get authentication info if available
      final authService = AuthService();
      final isLoggedIn = authService.isLoggedIn;
      final userId = authService.userId;
      final userEmail = authService.userEmail;
      
      print('📱 Registering FCM token with auth state:');
      print('   Is logged in: $isLoggedIn');
      print('   User ID: $userId');
      print('   User email: $userEmail');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/mobile/register-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': _customerId,
          'fcmToken': token,
          'deviceId': deviceId,
          'platform': 'flutter',
          'userId': userId,
          'userEmail': userEmail,
          'isAuthenticated': isLoggedIn,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ FCM token registered successfully');
      } else {
        print('❌ Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }

  void _handleTokenRefresh(String token) {
    print('🔥 FCM token refreshed: $token');
    _fcmToken = token;
    _registerFCMToken(token);
  }

  // Public API for FCM
  bool get isFCMInitialized => _fcmInitialized;

  void dispose() {
    _notificationListeners.clear();
    _recentNotifications.clear();
    _webSocketSubscription?.cancel();
    _webSocketService?.dispose();
    _authService?.removeListener(_onAuthStateChanged);
  }

  // Test notification - for development
  void sendTestNotification() {
    _handleNotificationReceived({
      'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Test Bildirim',
      'message': 'Bu test amaçlı bir bildirimdir.',
      'type': 'info',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}