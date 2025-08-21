import 'dart:convert';
import 'package:http/http.dart' as http;

class MetalsApiService {
  static const String baseUrl = 'https://api.api-ninjas.com/v1/commodityprice';
  static const String apiKey = 'qsHGB+VLocvWUHhJp1Hz2w==NMto19ZMjVwc7axC';
  
  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetchTime;
  static const Duration cacheDuration = Duration(minutes: 5);

  static Future<Map<String, dynamic>> getGoldPrice() async {
    try {
      // Check cache
      if (_cachedData != null && 
          _lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!) < cacheDuration) {
        return _cachedData!;
      }

      // Fetch gold price from API Ninjas
      final goldUrl = Uri.parse('$baseUrl?name=gold');
      print('API Ninjas: Fetching gold price from: $goldUrl');
      
      final goldResponse = await http.get(
        goldUrl,
        headers: {
          'X-Api-Key': apiKey,
        },
      );

      print('API Ninjas Gold: Response status: ${goldResponse.statusCode}');
      print('API Ninjas Gold: Response body: ${goldResponse.body}');
      
      if (goldResponse.statusCode == 200) {
        final goldData = json.decode(goldResponse.body);
        
        if (goldData != null && goldData['price'] != null) {
          // Gold price is per troy ounce in USD
          final goldUSD = (goldData['price'] as num).toDouble();
          
          // Get USD/TRY exchange rate (using fallback for now)
          final usdTry = 34.50; // You can fetch this from another API if needed
          
          final goldTRY = goldUSD * usdTry;
          
          // Calculate buy/sell prices with spread
          final buyPriceUSD = goldUSD * 0.995;
          final sellPriceUSD = goldUSD;
          final buyPriceTRY = goldTRY * 0.995;
          final sellPriceTRY = goldTRY;
          
          // Calculate change (mock data for now)
          final change = (DateTime.now().millisecond % 100 - 50) * 0.01;
          
          _cachedData = {
            'code': 'XAU/USD',
            'name': 'Ons Altın',
            'buyPriceUSD': buyPriceUSD,
            'sellPriceUSD': sellPriceUSD,
            'buyPriceTRY': buyPriceTRY,
            'sellPriceTRY': sellPriceTRY,
            'change': change,
            'isPositive': change > 0,
            'timestamp': DateTime.now().toIso8601String(),
            'usdTry': usdTry,
            'updated': goldData['updated'] ?? DateTime.now().toIso8601String(),
          };
          
          _lastFetchTime = DateTime.now();
          print('API Ninjas: Successfully fetched gold price: $goldUSD USD');
          return _cachedData!;
        } else {
          print('API Ninjas: Invalid response format');
        }
      } else {
        print('API Ninjas: Non-200 status code: ${goldResponse.statusCode}');
      }
      
      // Return fallback data if API fails
      print('API Ninjas: Using fallback data');
      return _getFallbackData();
    } catch (e) {
      print('Error fetching gold price from API Ninjas: $e');
      return _getFallbackData();
    }
  }

  static Map<String, dynamic> _getFallbackData() {
    return {
      'code': 'XAU/USD',
      'name': 'Ons Altın',
      'buyPriceUSD': 2731.25,
      'sellPriceUSD': 2746.85,
      'buyPriceTRY': 93268.25,
      'sellPriceTRY': 93800.00,
      'change': -0.25,
      'isPositive': false,
      'timestamp': DateTime.now().toIso8601String(),
      'usdTry': 34.15,
    };
  }
}