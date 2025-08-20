import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
  
  // Notification listeners
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];
  
  // Son bildirimleri sakla
  final List<Map<String, dynamic>> _recentNotifications = [];

  Future<void> initialize() async {
    print('🔔 NotificationService initializing...');
    await _initializeNotifications();
    await _loadLastNotificationId();
    
    // Start foreground polling
    _startPolling();
    
    print('🔔 Foreground notification polling started. Background polling will be handled separately.');
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