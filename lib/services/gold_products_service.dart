import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoldProductsService {
  static const String baseUrl = 'http://10.0.2.2:3009/api'; // Android emulator localhost
  static const String customerIdKey = 'customer_id';
  static const String defaultCustomerId = 'ffeee61a-8497-4c70-857e-c8f0efb13a2a';
  
  static List<Map<String, dynamic>>? _cachedProducts;
  static DateTime? _lastFetchTime;
  static const Duration cacheDuration = Duration(minutes: 1);

  // Get customer ID from preferences
  static Future<String> getCustomerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(customerIdKey) ?? defaultCustomerId;
    } catch (e) {
      print('Error getting customer ID: $e');
      return defaultCustomerId;
    }
  }

  // Fetch gold products from admin panel
  static Future<List<Map<String, dynamic>>> getGoldProducts() async {
    try {
      // Check cache
      if (_cachedProducts != null && 
          _lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!) < cacheDuration) {
        return _cachedProducts!;
      }

      final customerId = await getCustomerId();
      final url = Uri.parse('$baseUrl/customers/$customerId/gold-products');
      
      print('GoldProductsService: Fetching products from: $url');
      
      final response = await http.get(url);
      
      print('GoldProductsService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['products'] != null) {
          final products = List<Map<String, dynamic>>.from(data['products']);
          
          // Filter only active products
          final activeProducts = products
              .where((p) => p['is_active'] == 1 || p['is_active'] == true)
              .toList();
          
          // Sort by display_order
          activeProducts.sort((a, b) {
            final orderA = a['display_order'] ?? 999;
            final orderB = b['display_order'] ?? 999;
            return orderA.compareTo(orderB);
          });
          
          _cachedProducts = activeProducts;
          _lastFetchTime = DateTime.now();
          
          print('GoldProductsService: Loaded ${activeProducts.length} active products');
          return activeProducts;
        }
      }
      
      print('GoldProductsService: Failed to load products, using fallback');
      return _getFallbackProducts();
    } catch (e) {
      print('Error fetching gold products: $e');
      return _getFallbackProducts();
    }
  }

  // Get current gold price for calculations
  static Future<Map<String, dynamic>> getCurrentGoldPrice() async {
    try {
      final url = Uri.parse('$baseUrl/gold-price/current');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else if (data['fallback'] != null) {
          return data['fallback'];
        }
      }
      
      // Return fallback price
      return {
        'ounce_price_usd': 3381.6,
        'gram_price_usd': 108.73,
        'currency': 'USD',
        'source': 'Fallback'
      };
    } catch (e) {
      print('Error fetching gold price: $e');
      return {
        'ounce_price_usd': 3381.6,
        'gram_price_usd': 108.73,
        'currency': 'USD',
        'source': 'Fallback'
      };
    }
  }

  // Calculate product prices based on current gold price
  static Future<Map<String, dynamic>> calculateProductPrices(Map<String, dynamic> product) async {
    try {
      final goldPrice = await getCurrentGoldPrice();
      final gramPrice = goldPrice['gram_price_usd'] ?? 108.73;
      
      final weightGrams = (product['weight_grams'] ?? 0).toDouble();
      final buyMillesimal = (product['buy_millesimal'] ?? 0).toDouble();
      final sellMillesimal = (product['sell_millesimal'] ?? 0).toDouble();
      
      final buyPrice = gramPrice * weightGrams * buyMillesimal;
      final sellPrice = gramPrice * weightGrams * sellMillesimal;
      
      // Mock change data for now
      final change = (DateTime.now().millisecond % 100 - 50) * 0.01;
      
      return {
        'code': product['id'] ?? 'GOLD',
        'name': product['name'] ?? 'Altın',
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'change': change,
        'isPositive': change > 0,
        'weight_grams': weightGrams,
        'buy_millesimal': buyMillesimal,
        'sell_millesimal': sellMillesimal,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error calculating product prices: $e');
      return {
        'code': product['id'] ?? 'GOLD',
        'name': product['name'] ?? 'Altın',
        'buyPrice': 0.0,
        'sellPrice': 0.0,
        'change': 0.0,
        'isPositive': false,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get all products with calculated prices
  static Future<List<Map<String, dynamic>>> getProductsWithPrices() async {
    try {
      final products = await getGoldProducts();
      final productsWithPrices = <Map<String, dynamic>>[];
      
      for (final product in products) {
        final pricesData = await calculateProductPrices(product);
        productsWithPrices.add(pricesData);
      }
      
      return productsWithPrices;
    } catch (e) {
      print('Error getting products with prices: $e');
      return _getFallbackProducts();
    }
  }

  // Fallback products when API is unavailable
  static List<Map<String, dynamic>> _getFallbackProducts() {
    return [
      {
        'code': 'ONSALTIN',
        'name': 'Ons Altın',
        'buyPrice': 3365.29,
        'sellPrice': 3381.60,
        'change': -0.25,
        'isPositive': false,
        'weight_grams': 31.1035,
        'buy_millesimal': 0.995,
        'sell_millesimal': 1.000,
        'timestamp': DateTime.now().toIso8601String(),
      }
    ];
  }

  // Clear cache to force refresh
  static void clearCache() {
    _cachedProducts = null;
    _lastFetchTime = null;
  }
}