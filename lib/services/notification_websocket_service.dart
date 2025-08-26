import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'auth_service.dart';

class NotificationWebSocketService extends ChangeNotifier {
  static final NotificationWebSocketService _instance = NotificationWebSocketService._internal();
  factory NotificationWebSocketService() => _instance;
  NotificationWebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  // Stream controller for notification events
  final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  // WebSocket URL - Android emulator localhost
  static const String _wsUrl = 'ws://10.0.2.2:3009/socket.io/?EIO=4&transport=websocket';

  // Auth service reference
  AuthService? _authService;

  Future<void> initialize() async {
    print('🔔 NotificationWebSocketService initializing...');
    _authService = AuthService();
    
    // Listen to auth state changes
    _authService!.addListener(_onAuthStateChanged);
    
    // Initial connection
    await connect();
  }

  void _onAuthStateChanged() {
    print('🔄 Auth state changed, reconnecting WebSocket with new auth state...');
    // Reconnect with new auth state
    disconnect();
    connect();
  }

  Future<void> connect() async {
    if (_isConnected) {
      print('🔌 Notification WebSocket already connected');
      return;
    }

    try {
      print('🔌 Connecting to Notification WebSocket: $_wsUrl');
      
      // Add auth query params if user is logged in
      String wsUrlWithAuth = _wsUrl;
      if (_authService?.isLoggedIn == true) {
        final userId = _authService!.userId;
        final userEmail = _authService!.userEmail;
        print('🔐 Connecting as authenticated user: $userEmail (ID: $userId)');
      } else {
        print('👤 Connecting as guest user');
      }
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrlWithAuth),
        connectTimeout: const Duration(seconds: 10),
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      print('✅ Notification WebSocket connected successfully');

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('❌ Notification WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('🔌 Notification WebSocket connection closed');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      // Send initial handshake after connection
      Timer(const Duration(milliseconds: 500), () {
        _sendAuthenticationInfo();
      });

      // Start ping timer to keep connection alive
      _startPingTimer();

    } catch (e) {
      print('❌ Failed to connect Notification WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _sendAuthenticationInfo() async {
    if (!_isConnected || _channel == null) return;

    try {
      if (_authService?.isLoggedIn == true) {
        // Send authentication info for logged in user
        final authData = {
          'userId': _authService!.userId,
          'userEmail': _authService!.userEmail,
          'authToken': _authService!.authToken,
          'isAuthenticated': true,
        };
        
        // Socket.IO format for custom event with auth data
        final authMessage = '42["authenticate",${json.encode(authData)}]';
        _channel!.sink.add(authMessage);
        print('🔐 Sent authentication info for user: ${_authService!.userEmail}');
        
        // Also join user-specific room
        final joinMessage = '42["join_user","${_authService!.userId}"]';
        _channel!.sink.add(joinMessage);
        print('📤 Joined user room: ${_authService!.userId}');
      } else {
        // Send guest identification
        final deviceId = await _getDeviceId();
        final guestData = {
          'isAuthenticated': false,
          'deviceId': deviceId,
        };
        
        final guestMessage = '42["identify_guest",${json.encode(guestData)}]';
        _channel!.sink.add(guestMessage);
        print('👤 Identified as guest user with device: $deviceId');
        
        // Join guest room
        _channel!.sink.add('42["join_guests"]');
        print('📤 Joined guests room');
      }
      
      // Always join the 'all' room for broadcast notifications
      _channel!.sink.add('42["join_all"]');
      print('📤 Joined all users room');
      
    } catch (e) {
      print('❌ Error sending authentication info: $e');
    }
  }

  Future<String> _getDeviceId() async {
    // This should match the device ID used in AuthService
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = timestamp % 10000;
      deviceId = 'dev_${timestamp}_$random';
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        // Send Socket.IO ping
        _channel!.sink.add('2');
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        // Socket.IO messages handling
        if (message.startsWith('42')) {
          // Extract JSON part
          final jsonPart = message.substring(2);
          final decoded = json.decode(jsonPart);
          
          if (decoded is List && decoded.length >= 2) {
            final eventName = decoded[0];
            final eventData = decoded[1];
            
            print('📨 WebSocket received: $eventName');
            
            switch (eventName) {
              case 'notification_sent':
                print('🔔 Notification received: ${eventData['title']}');
                print('   Target: ${eventData['target']}');
                print('   Type: ${eventData['type']}');
                _handleNotification(eventData);
                break;
              case 'authenticated':
                print('✅ WebSocket authentication confirmed: ${eventData}');
                break;
              case 'user_joined':
                print('✅ Successfully joined user notification room');
                break;
              case 'guest_joined':
                print('✅ Successfully joined guest notification room');
                break;
              case 'error':
                print('❌ WebSocket error: ${eventData['message']}');
                break;
              default:
                // Other events
                break;
            }
          }
        } else if (message == '2') {
          // Socket.IO ping - respond with pong
          _channel?.sink.add('3');
        } else if (message == '3') {
          // Socket.IO pong received - connection is alive
        } else if (message.startsWith('0')) {
          // Connection handshake
          print('🤝 WebSocket handshake received');
          // Send authentication info after handshake
          Timer(const Duration(milliseconds: 100), () {
            _sendAuthenticationInfo();
          });
        }
      }
    } catch (e) {
      print('⚠️ Error handling WebSocket message: $e');
    }
  }

  void _handleNotification(Map<String, dynamic> notificationData) {
    // Check if this notification is for the current user
    final target = notificationData['target'];
    final isLoggedIn = _authService?.isLoggedIn ?? false;
    final userId = _authService?.userId;
    
    // Determine if we should show this notification
    bool shouldShow = false;
    
    if (target == 'all') {
      // Show to everyone
      shouldShow = true;
    } else if (target == 'guests' && !isLoggedIn) {
      // Show only to guests
      shouldShow = true;
    } else if (target == 'authenticated' && isLoggedIn) {
      // Show only to authenticated users
      shouldShow = true;
    } else if (target == userId) {
      // Show only to specific user
      shouldShow = true;
    } else if (target is List && target.contains(userId)) {
      // Show to specific group of users
      shouldShow = true;
    }
    
    if (shouldShow) {
      print('✅ Notification is for current user, emitting...');
      // Emit notification to listeners
      _notificationController.add(notificationData);
    } else {
      print('⏭️ Notification not for current user (target: $target, isLoggedIn: $isLoggedIn, userId: $userId)');
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
    _pingTimer?.cancel();

    // Schedule reconnection if not exceeded max attempts
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      print('🔄 Scheduling WebSocket reconnection (attempt $_reconnectAttempts/$_maxReconnectAttempts)...');
      
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        connect();
      });
    } else {
      print('❌ Max WebSocket reconnection attempts reached');
    }
  }

  void disconnect() {
    print('🔌 Disconnecting Notification WebSocket...');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  void dispose() {
    _authService?.removeListener(_onAuthStateChanged);
    disconnect();
    _notificationController.close();
    super.dispose();
  }

  bool get isConnected => _isConnected;
  
  // Force reconnect with authentication
  void forceReconnect() {
    print('🔄 Force reconnecting WebSocket with current auth state...');
    disconnect();
    _reconnectAttempts = 0; // Reset attempts for forced reconnect
    connect();
  }
}