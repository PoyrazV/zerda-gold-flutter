import 'package:dio/dio.dart';

class CurrencyApiService {
  static final CurrencyApiService _instance = CurrencyApiService._internal();
  factory CurrencyApiService() => _instance;

  late Dio _dio;
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';

  CurrencyApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<Map<String, dynamic>?> getLatestRates() async {
    try {
      // TRY bazında tüm kurları al - API key gerektirmiyor
      final response = await _dio.get('TRY');

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('API hatası: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getFormattedCurrencyData() async {
    final data = await getLatestRates();
    if (data == null || data['rates'] == null) {
      return [];
    }

    final rates = data['rates'] as Map<String, dynamic>;
    
    final currencyNames = {
      'USD': 'Amerikan Doları',
      'EUR': 'Euro', 
      'GBP': 'İngiliz Sterlini',
      'CHF': 'İsviçre Frangı',
      'AUD': 'Avustralya Doları',
      'CAD': 'Kanada Doları',
      'JPY': 'Japon Yeni',
      'SEK': 'İsveç Kronu',
      'NOK': 'Norveç Kronu',
      'DKK': 'Danimarka Kronu',
      'PLN': 'Polonya Zlotisi',
      'CZK': 'Çek Korunası',
      'HUF': 'Macar Forinti',
      'RON': 'Rumen Leyi',
      'BGN': 'Bulgar Levası',
      'HRK': 'Hırvat Kunası',
      'RUB': 'Rus Rublesi',
      'UAH': 'Ukrayna Grivnası',
      'CNY': 'Çin Yuanı',
      'KRW': 'Güney Kore Wonu',
      'INR': 'Hindistan Rupisi',
      'SGD': 'Singapur Doları',
      'HKD': 'Hong Kong Doları',
      'MYR': 'Malezya Ringiti',
      'THB': 'Tayland Bahtı',
      'PHP': 'Filipinler Pesosu',
      'IDR': 'Endonezya Rupiahı',
      'NZD': 'Yeni Zelanda Doları',
      'ZAR': 'Güney Afrika Randı',
      'BRL': 'Brezilya Reali',
      'MXN': 'Meksika Pesosu',
      'ARS': 'Arjantin Pesosu',
      'CLP': 'Şili Pesosu',
      'COP': 'Kolombiya Pesosu',
      'PEN': 'Peru Solü',
      'UYU': 'Uruguay Pesosu',
      'SAR': 'Suudi Arabistan Riyali',
      'AED': 'BAE Dirhemi',
      'QAR': 'Katar Riyali',
      'KWD': 'Kuveyt Dinarı',
      'BHD': 'Bahreyn Dinarı',
      'OMR': 'Umman Riyali',
      'JOD': 'Ürdün Dinarı',
      'LBP': 'Lübnan Lirası',
      'EGP': 'Mısır Poundu',
      'MAD': 'Fas Dirhemi',
      'DZD': 'Cezayir Dinarı',
      'TND': 'Tunus Dinarı',
      'LYD': 'Libya Dinarı',
      'ETB': 'Etiyopya Birri',
      'KES': 'Kenya Şilini',
      'UGX': 'Uganda Şilini',
      'TZS': 'Tanzanya Şilini',
      'GHS': 'Gana Cedisi',
      'NGN': 'Nijerya Nairası',
      'XOF': 'CFA Frank BCEAO',
      'XAF': 'CFA Frank BEAC',
      'MGA': 'Madagaskar Ariarysi',
      'MUR': 'Mauritius Rupisi',
      'SCR': 'Seyşeller Rupisi',
      'MWK': 'Malavi Kvaçası',
      'ZMW': 'Zambiya Kvaçası',
      'BWP': 'Botsvana Pulası',
      'SZL': 'Esvatini Lilangeni',
      'LSL': 'Lesoto Loti',
      'NAD': 'Namibya Doları',
      'AFN': 'Afganistan Afganisi',
      'PKR': 'Pakistan Rupisi',
      'LKR': 'Sri Lanka Rupisi',
      'BDT': 'Bangladeş Takası',
      'NPR': 'Nepal Rupisi',
      'BTN': 'Bhutan Ngultrumu',
      'MMK': 'Myanmar Kyatı',
      'LAK': 'Laos Kipi',
      'KHR': 'Kamboçya Rieli',
      'VND': 'Vietnam Dongu',
      'MNT': 'Moğolistan Tugrugu',
      'KZT': 'Kazakistan Tengesi',
      'UZS': 'Özbekistan Somu',
      'KGS': 'Kırgızistan Somu',
      'TJS': 'Tacikistan Somonisi',
      'TMT': 'Türkmenistan Manatı',
      'AZN': 'Azerbaycan Manatı',
      'GEL': 'Gürcistan Larisi',
      'AMD': 'Ermenistan Dramı',
      'BYN': 'Belarus Rublesi',
      'MDL': 'Moldova Leyi',
      'ALL': 'Arnavutluk Leki',
      'MKD': 'Kuzey Makedonya Dinarı',
      'RSD': 'Sırbistan Dinarı',
      'BAM': 'Bosna-Hersek Markı',
      'ISK': 'İzlanda Kronu',
    };

    List<Map<String, dynamic>> formattedData = [];

    // TRY bazında kurlar - ters çevir
    currencyNames.forEach((key, name) {
      if (rates.containsKey(key)) {
        double rate = rates[key]?.toDouble() ?? 1.0;
        
        // TRY bazında kur, ters çevir (1 USD = x TRY)
        double tryPrice = 1.0 / rate;
        
        double buyPrice = tryPrice * 0.9985;  // Alış daha düşük
        double sellPrice = tryPrice * 1.0015; // Satış daha yüksek
        
        // Küçük değerli para birimleri için özel hesaplama
        if (['JPY', 'KRW', 'IDR', 'VND', 'UGX', 'TZS', 'MGA', 'MWK', 'LAK', 'KHR', 'MNT', 'UZS', 'LBP', 'IRR'].contains(key)) {
          buyPrice = buyPrice / 100;
          sellPrice = sellPrice / 100;
        }
        
        // Çok küçük değerli para birimleri (1000'de bir hesaplama)
        if (['IDR', 'VND', 'UGX', 'LAK', 'UZS', 'IRR'].contains(key)) {
          buyPrice = buyPrice / 10;
          sellPrice = sellPrice / 10;
        }
        
        // Rastgele değişim yüzdesi
        double changePercent = (DateTime.now().millisecond % 200 - 100) * 0.01;
        
        formattedData.add({
          "code": "${key}TRY",
          "name": name,
          "buyPrice": buyPrice,
          "sellPrice": sellPrice,
          "change": changePercent,
          "isPositive": changePercent >= 0,
          "timestamp": _getCurrentTime(),
        });
      }
    });

    return formattedData;
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  // Historical data endpoints - Free tier doesn't support historical data
  Future<Map<String, dynamic>?> getHistoricalData({
    required String date, // Format: YYYY-MM-DD
    String base = 'TRY',
  }) async {
    try {
      // exchangerate-api.com historical endpoint (not available in free tier)
      final response = await _dio.get('$date/TRY');
      
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Historical API hatası (beklenen - free tier): $e');
      // Free tier doesn't support historical data, return null to use mock data
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getChartData({
    required String symbol,
    int days = 30,
  }) async {
    // Free tier API doesn't support historical data, use enhanced mock data
    print('Chart data: Historical API not available in free tier, using enhanced mock data');
    return _generateMockChartData(symbol, days);
  }

  List<Map<String, dynamic>> _generateMockChartData(String symbol, int days) {
    final now = DateTime.now();
    final basePrice = _getBasePriceForSymbol(symbol);
    List<Map<String, dynamic>> mockData = [];
    
    double currentPrice = basePrice;
    
    // Create more realistic price patterns
    for (int i = days; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      // More realistic price movement with trends
      final volatility = _getVolatilityForSymbol(symbol);
      final trendFactor = _getTrendFactor(i, days);
      
      // Use deterministic randomness based on date for consistency
      final seed = date.day + date.month * 31 + symbol.hashCode;
      final random = (seed % 200 - 100) / 1000.0;
      
      final dailyChange = (random * volatility) + trendFactor;
      currentPrice *= (1 + dailyChange);
      
      // Ensure price stays within reasonable bounds
      final minPrice = basePrice * 0.7;
      final maxPrice = basePrice * 1.3;
      currentPrice = currentPrice.clamp(minPrice, maxPrice);
      
      mockData.add({
        'date': date.millisecondsSinceEpoch,
        'price': currentPrice,
        'volume': _generateRealisticVolume(date),
      });
    }
    
    return mockData;
  }

  double _getVolatilityForSymbol(String symbol) {
    switch (symbol) {
      case 'USDTRY':
      case 'EURTRY':
      case 'GBPTRY':
        return 0.015; // 1.5% daily volatility for major pairs
      case 'JPYTRY':
      case 'CHFTRY':
        return 0.012; // Lower volatility
      default:
        return 0.02; // 2% for exotic pairs
    }
  }

  double _getTrendFactor(int daysBack, int totalDays) {
    // Subtle long-term trend
    final trendStrength = 0.0001;
    final trendDirection = (totalDays.hashCode % 2 == 0) ? 1 : -1;
    return trendDirection * trendStrength * (totalDays - daysBack) / totalDays;
  }

  int _generateRealisticVolume(DateTime date) {
    // Higher volume on weekdays, lower on weekends
    final isWeekend = date.weekday >= 6;
    final baseVolume = isWeekend ? 300000 : 800000;
    final variance = date.day % 400000;
    return baseVolume + variance;
  }

  double _getBasePriceForSymbol(String symbol) {
    switch (symbol) {
      case 'USDTRY': return 34.60;
      case 'EURTRY': return 37.50;
      case 'GBPTRY': return 43.80;
      case 'CHFTRY': return 39.20;
      case 'AUDTRY': return 22.90;
      case 'CADTRY': return 25.95;
      case 'JPYTRY': return 0.23;
      case 'SEKTRY': return 3.12;
      default: return 34.60;
    }
  }
}