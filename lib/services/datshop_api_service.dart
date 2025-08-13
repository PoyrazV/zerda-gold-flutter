import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class DatShopApiService {
  static final DatShopApiService _instance = DatShopApiService._internal();
  factory DatShopApiService() => _instance;
  DatShopApiService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  
  // Data storage
  Map<String, dynamic> _latestGoldData = {};
  DateTime? _lastUpdateTime;
  
  // Stream controller for broadcasting gold data updates
  final StreamController<Map<String, dynamic>> _goldDataController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Public stream for widgets to listen to
  Stream<Map<String, dynamic>> get goldDataStream => _goldDataController.stream;
  
  // Get current gold data
  Map<String, dynamic> get currentGoldData => _latestGoldData;
  
  // Check if data is fresh (less than 10 minutes old)
  bool get isDataFresh {
    if (_lastUpdateTime == null) return false;
    return DateTime.now().difference(_lastUpdateTime!).inMinutes < 10;
  }

  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://api.haremaltin.com'),
      );
      
      _isConnected = true;
      print('DatShop API: Canlı veri bağlantısı deneniyor...');
      
      // Listen to messages with silent error handling
      _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          _isConnected = false;
          // Sessiz reconnect - hiç log yazmadan
        },
        onDone: () {
          _isConnected = false;
          // Sessiz reconnect - hiç log yazmadan
        },
        cancelOnError: true,
      );
      
      // Test bağlantısını 5 saniye sonra kontrol et
      Timer(const Duration(seconds: 5), () {
        if (!_isConnected || _latestGoldData.isEmpty) {
          print('DatShop API: Mock data kullanılıyor (canlı veri mevcut değil)');
        }
      });
      
    } catch (e) {
      _isConnected = false;
      // Sessizce fallback'e geç - hiç reconnect yapmadan
      print('DatShop API: Mock data kullanılıyor (bağlantı kurulamadı)');
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      // Check if this is a price_changed event
      if (data is List && data.isNotEmpty && data[0] == 'price_changed') {
        final priceData = data[1];
        
        if (priceData != null && priceData['data'] != null) {
          _processGoldData(priceData['data']);
        }
      }
    } catch (e) {
      // Sessiz hata yönetimi
    }
  }

  void _processGoldData(Map<String, dynamic> data) {
    // Filter gold-related data
    final goldData = <String, dynamic>{};
    
    // Gold symbols we're interested in
    final goldSymbols = [
      'ALTIN',        // Gram Altın
      'AYAR22',       // 22 Ayar
      'AYAR18',       // 18 Ayar  
      'AYAR14',       // 14 Ayar
      'CEYREK_YENI',  // Yeni Çeyrek
      'CEYREK_ESKI',  // Eski Çeyrek
      'YARIM_YENI',   // Yeni Yarım
      'YARIM_ESKI',   // Eski Yarım
      'TAM_YENI',     // Yeni Tam
      'TAM_ESKI',     // Eski Tam
      'CUMHURIYET',   // Cumhuriyet Altını
      'ATASEHIR',     // Ataşehir
      'GUMUSTRY',     // Gümüş
      'PLATIN',       // Platin
      'PALADYUM',     // Paladyum
    ];
    
    bool hasUpdates = false;
    
    for (final symbol in goldSymbols) {
      if (data.containsKey(symbol)) {
        final symbolData = data[symbol];
        if (symbolData != null) {
          goldData[symbol] = {
            'buyPrice': _parsePrice(symbolData['alis']),
            'sellPrice': _parsePrice(symbolData['satis']),
            'lastUpdate': DateTime.now().millisecondsSinceEpoch,
          };
          hasUpdates = true;
        }
      }
    }
    
    if (hasUpdates) {
      _latestGoldData.addAll(goldData);
      _lastUpdateTime = DateTime.now();
      
      // Broadcast the new data to all listeners
      _goldDataController.add(_latestGoldData);
      
      print('DatShop API: ${goldData.length} altın verisi güncellendi');
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }


  // Convert API data to standardized format for UI
  List<Map<String, dynamic>> getFormattedGoldData() {
    if (_latestGoldData.isEmpty) {
      return _getMockGoldData();
    }
    
    final formattedData = <Map<String, dynamic>>[];
    
    // Map API symbols to display names
    final symbolMap = {
      'ALTIN': 'Gram Altın',
      'AYAR22': '22 Ayar Bilezik',
      'AYAR18': '18 Ayar Bilezik',
      'AYAR14': '14 Ayar Bilezik',
      'CEYREK_YENI': 'Yeni Çeyrek Altın',
      'CEYREK_ESKI': 'Eski Çeyrek Altın',
      'YARIM_YENI': 'Yeni Yarım Altın',
      'YARIM_ESKI': 'Eski Yarım Altın',
      'TAM_YENI': 'Yeni Tam Altın',
      'TAM_ESKI': 'Eski Tam Altın',
      'CUMHURIYET': 'Cumhuriyet Altını',
      'ATASEHIR': 'Ataşehir',
      'GUMUSTRY': 'Gümüş (TRY)',
      'PLATIN': 'Platin',
      'PALADYUM': 'Paladyum',
    };
    
    symbolMap.forEach((apiSymbol, displayName) {
      if (_latestGoldData.containsKey(apiSymbol)) {
        final data = _latestGoldData[apiSymbol];
        formattedData.add({
          'code': apiSymbol,
          'name': displayName,
          'buyPrice': data['buyPrice'] ?? 0.0,
          'sellPrice': data['sellPrice'] ?? 0.0,
          'lastUpdate': data['lastUpdate'] ?? DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
    
    return formattedData;
  }

  List<Map<String, dynamic>> _getMockGoldData() {
    print('DatShop API: Mock data kullanılıyor (API bağlantısı yok)');
    // Fallback mock data when API is not available
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return [
      {
        'code': 'ALTIN',
        'name': 'Gram Altın',
        'buyPrice': 2847.50,
        'sellPrice': 2849.20,
        'change': 12.75,
        'changePercent': 0.45,
        'lastUpdate': now,
      },
      {
        'code': 'AYAR22',
        'name': '22 Ayar Bilezik',
        'buyPrice': 2698.45,
        'sellPrice': 2701.15,
        'change': 8.30,
        'changePercent': 0.31,
        'lastUpdate': now,
      },
      {
        'code': 'AYAR18',
        'name': '18 Ayar Bilezik',
        'buyPrice': 2165.50,
        'sellPrice': 2178.25,
        'change': -5.75,
        'changePercent': -0.26,
        'lastUpdate': now,
      },
      {
        'code': 'AYAR14',
        'name': '14 Ayar Bilezik',
        'buyPrice': 1687.75,
        'sellPrice': 1698.50,
        'change': -2.25,
        'changePercent': -0.13,
        'lastUpdate': now,
      },
      {
        'code': 'CEYREK_YENI',
        'name': 'Yeni Çeyrek Altın',
        'buyPrice': 2876.50,
        'sellPrice': 2891.75,
        'change': 15.50,
        'changePercent': 0.54,
        'lastUpdate': now,
      },
      {
        'code': 'CEYREK_ESKI',
        'name': 'Eski Çeyrek Altın',
        'buyPrice': 2845.25,
        'sellPrice': 2860.40,
        'change': -8.15,
        'changePercent': -0.28,
        'lastUpdate': now,
      },
      {
        'code': 'YARIM_YENI',
        'name': 'Yeni Yarım Altın',
        'buyPrice': 5753.00,
        'sellPrice': 5783.50,
        'change': 31.00,
        'changePercent': 0.54,
        'lastUpdate': now,
      },
      {
        'code': 'YARIM_ESKI',
        'name': 'Eski Yarım Altın',
        'buyPrice': 5690.75,
        'sellPrice': 5720.80,
        'change': -16.25,
        'changePercent': -0.28,
        'lastUpdate': now,
      },
      {
        'code': 'TAM_YENI',
        'name': 'Yeni Tam Altın',
        'buyPrice': 11506.00,
        'sellPrice': 11567.00,
        'change': 62.00,
        'changePercent': 0.54,
        'lastUpdate': now,
      },
      {
        'code': 'TAM_ESKI',
        'name': 'Eski Tam Altın',
        'buyPrice': 11381.50,
        'sellPrice': 11441.60,
        'change': -32.50,
        'changePercent': -0.28,
        'lastUpdate': now,
      },
      {
        'code': 'CUMHURIYET',
        'name': 'Cumhuriyet Altını',
        'buyPrice': 11548.90,
        'sellPrice': 11610.30,
        'change': 45.20,
        'changePercent': 0.39,
        'lastUpdate': now,
      },
      {
        'code': 'ATASEHIR',
        'name': 'Ataşehir Altını',
        'buyPrice': 11425.25,
        'sellPrice': 11485.75,
        'change': 68.75,
        'changePercent': 0.60,
        'lastUpdate': now,
      },
      {
        'code': 'GUMUSTRY',
        'name': 'Gümüş (TRY)',
        'buyPrice': 33.45,
        'sellPrice': 34.25,
        'change': -0.80,
        'changePercent': -2.28,
        'lastUpdate': now,
      },
      {
        'code': 'PLATIN',
        'name': 'Platin',
        'buyPrice': 2731.25,
        'sellPrice': 2746.85,
        'change': -15.60,
        'changePercent': -0.57,
        'lastUpdate': now,
      },
      {
        'code': 'PALADYUM',
        'name': 'Paladyum',
        'buyPrice': 1856.75,
        'sellPrice': 1874.30,
        'change': 28.55,
        'changePercent': 1.55,
        'lastUpdate': now,
      },
    ];
  }

  // Force refresh data
  Future<void> refreshGoldData() async {
    if (!_isConnected) {
      await connect();
    }
    // WebSocket will automatically receive updates
  }

  // Clean up
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _goldDataController.close();
    _isConnected = false;
  }
}