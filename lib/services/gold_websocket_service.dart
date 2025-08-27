import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'gold_products_service.dart';

class GoldWebSocketService {
  static GoldWebSocketService? _instance;
  static GoldWebSocketService get instance {
    _instance ??= GoldWebSocketService._internal();
    return _instance!;
  }

  GoldWebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  // Stream controller for gold product updates
  final StreamController<Map<String, dynamic>> _goldUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get goldUpdates => _goldUpdatesController.stream;

  // WebSocket URL - Android emulator localhost
  static const String _wsUrl = 'ws://10.0.2.2:3009';

  Future<void> connect() async {
    if (_isConnected) {
      print('🔌 WebSocket already connected');
      return;
    }

    try {
      print('🔌 Connecting to WebSocket: $_wsUrl');
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(_wsUrl),
        connectTimeout: const Duration(seconds: 10),
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      print('✅ WebSocket connected successfully');

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      // Parse the message
      Map<String, dynamic> data;
      
      if (message is String) {
        // Socket.IO messages come with event type prefix
        // Format: 42["event-name",{data}]
        if (message.startsWith('42')) {
          // Extract JSON part
          final jsonPart = message.substring(2);
          final decoded = json.decode(jsonPart);
          
          if (decoded is List && decoded.length >= 2) {
            final eventName = decoded[0];
            final eventData = decoded[1];
            
            if (eventName == 'gold-products-updated') {
              print('📨 Gold products update received: $eventData');
              
              // Clear cache to force refresh
              GoldProductsService.clearCache();
              
              // Notify listeners
              _goldUpdatesController.add(eventData);
            }
          }
        } else if (message == '2') {
          // Socket.IO ping
          _channel?.sink.add('3'); // Send pong
        }
      }
    } catch (e) {
      print('⚠️ Error handling WebSocket message: $e');
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;

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
    print('🔌 Disconnecting WebSocket...');
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  void dispose() {
    disconnect();
    _goldUpdatesController.close();
  }

  bool get isConnected => _isConnected;
}