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

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if it hasn't been initialized yet
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  print('🔥 Background message received: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Initialize local notifications plugin for background
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'zerda_notifications',
    'Zerda Notifications',
    description: 'Zerda Gold notifications',
    importance: Importance.high,
  );
  
  // Initialize with Android settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
      
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Create notification details
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'zerda_notifications',
    'Zerda Notifications',
    channelDescription: 'Zerda Gold notifications',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  
  const NotificationDetails details = NotificationDetails(android: androidDetails);
  
  // Show the notification
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'Zerda Gold',
    message.notification?.body ?? '',
    details,
    payload: message.data.toString(),
  );
  
  // Save to SharedPreferences for later retrieval
  try {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('background_notifications') ?? [];
    notifications.add(jsonEncode({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList('background_notifications', notifications);
  } catch (e) {
    print('❌ Error saving background notification: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Timer? _pollingTimer;
  bool _isPolling = false;
  String? _lastNotificationId;

  // Admin panel HTTP URL
  static const String _baseUrl = 'http://10.0.2.2:3009';
  static const String _customerId = '112e0e89-1c16-485d-acda-d0a21a24bb95';
  
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

  Future<void> initialize() async {
    print('🔔 NotificationService initializing...');
    
    // Initialize Firebase and FCM first
    await _initializeFirebase();
    
    // Initialize local notifications
    await _initializeNotifications();
    await _loadLastNotificationId();
    
    // Check for background notifications
    await _checkBackgroundNotifications();
    
    // Start foreground polling for backward compatibility
    _startPolling();
    
    print('🔔 NotificationService fully initialized with FCM support');
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
      
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
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

  Future<void> _loadLastNotificationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Reset last notification ID to get all notifications
      await prefs.remove('last_notification_id');
      _lastNotificationId = null;
      print('📖 Reset last notification ID to get all notifications');
    } catch (e) {
      print('❌ Failed to load last notification ID: $e');
    }
  }

  Future<void> _saveLastNotificationId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notification_id', id);
      _lastNotificationId = id;
    } catch (e) {
      print('❌ Failed to save last notification ID: $e');
    }
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

  void _startPolling() {
    if (_isPolling) return;
    
    _isPolling = true;
    print('🔄 Starting notification polling...');
    
    // Poll every 3 seconds for new notifications
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkForNewNotifications();
    });
  }

  Future<void> _checkForNewNotifications() async {
    try {
      // Use public mobile endpoint that doesn't require authentication
      String url = '$_baseUrl/api/mobile/notifications/$_customerId';
      if (_lastNotificationId != null) {
        url += '?since=$_lastNotificationId';
      }
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final notifications = data['notifications'] as List;
          
          print('📡 Polling check: Found ${notifications.length} notifications');
          
          // Process new notifications (they're already filtered by 'since' parameter)
          for (final notification in notifications) {
            final notificationId = notification['id'].toString();
            print('🔔 New notification found: ${notification['title']} (ID: $notificationId)');
            _handleNotificationReceived(Map<String, dynamic>.from(notification));
            await _saveLastNotificationId(notificationId);
          }
        }
      } else {
        print('❌ Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error checking notifications: $e');
    }
  }

  bool _isNewerNotification(String newId, String lastId) {
    // Simple comparison - in real app you might use timestamps
    try {
      final newIdNum = int.tryParse(newId) ?? 0;
      final lastIdNum = int.tryParse(lastId) ?? 0;
      return newIdNum > lastIdNum;
    } catch (e) {
      return newId != lastId;
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

  bool get isConnected => _isPolling;

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
    print('🔥 FCM foreground message: ${message.notification?.title}');
    
    // Convert FCM message to our notification format
    final notificationData = _fcmMessageToNotificationData(message);
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
    return {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? 'Zerda Gold',
      'message': message.notification?.body ?? 'Yeni bildirim',
      'type': message.data['type'] ?? 'info',
      'timestamp': DateTime.now().toIso8601String(),
      'data': message.data,
    };
  }

  Future<void> _registerFCMToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/mobile/register-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': _customerId,
          'fcmToken': token,
          'platform': 'flutter',
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
  String? get fcmToken => _fcmToken;
  bool get isFCMInitialized => _fcmInitialized;

  void dispose() {
    _pollingTimer?.cancel();
    _isPolling = false;
    _notificationListeners.clear();
    _recentNotifications.clear();
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