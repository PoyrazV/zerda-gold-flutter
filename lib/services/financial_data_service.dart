class FinancialDataService {
  // Singleton pattern
  static final FinancialDataService _instance = FinancialDataService._internal();
  factory FinancialDataService() => _instance;
  FinancialDataService._internal();

  // Currency data - tek merkezi kaynak
  static final List<Map<String, dynamic>> currencyData = [
    {
      "code": "USDTRY",
      "name": "Amerikan Doları",
      "buyPrice": 34.5842,
      "sellPrice": 34.5958,
      "change": -0.03,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "EURTRY", 
      "name": "Euro",
      "buyPrice": 37.4763,
      "sellPrice": 37.4891,
      "change": 0.42,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "GBPTRY",
      "name": "İngiliz Sterlini",
      "buyPrice": 43.7924,
      "sellPrice": 43.8056,
      "change": 0.26,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "CHFTRY",
      "name": "İsviçre Frangı",
      "buyPrice": 39.2134,
      "sellPrice": 39.2267,
      "change": -0.15,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "AUDTRY",
      "name": "Avustralya Doları", 
      "buyPrice": 22.8934,
      "sellPrice": 22.9012,
      "change": 0.08,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "CADTRY",
      "name": "Kanada Doları",
      "buyPrice": 25.9421,
      "sellPrice": 25.9501,
      "change": -0.21,
      "isPositive": false,
      "timestamp": "10:12",
    },
    {
      "code": "JPYTRY",
      "name": "Japon Yeni", 
      "buyPrice": 0.2321,
      "sellPrice": 0.2324,
      "change": 0.41,
      "isPositive": true,
      "timestamp": "10:12",
    },
    {
      "code": "SEKTRY",
      "name": "İsveç Kronu",
      "buyPrice": 3.1234,
      "sellPrice": 3.1267,
      "change": 0.18,
      "isPositive": true,
      "timestamp": "10:12",
    },
  ];

  // Gold data - tek merkezi kaynak
  static final List<Map<String, dynamic>> goldData = [
    {
      "code": "GRAM",
      "name": "Gram Altın",
      "buyPrice": 2640.50,
      "sellPrice": 2654.30,
      "change": 0.65,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "YÇEYREK",
      "name": "Yeni Çeyrek Altın",
      "buyPrice": 2876.50,
      "sellPrice": 2891.75,
      "change": 0.85,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "EÇEYREK", 
      "name": "Eski Çeyrek Altın",
      "buyPrice": 2845.25,
      "sellPrice": 2860.40,
      "change": -0.45,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "YYARIM",
      "name": "Yeni Yarım Altın",
      "buyPrice": 5753.00,
      "sellPrice": 5783.50,
      "change": 1.12,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "EYARIM",
      "name": "Eski Yarım Altın", 
      "buyPrice": 5698.25,
      "sellPrice": 5728.90,
      "change": -0.23,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "YTAM",
      "name": "Yeni Tam Altın",
      "buyPrice": 11506.00,
      "sellPrice": 11567.00,
      "change": 0.95,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "ETAM",
      "name": "Eski Tam Altın",
      "buyPrice": 11396.50,
      "sellPrice": 11457.80,
      "change": -1.05,
      "isPositive": false,
      "timestamp": "10:15",
    },
    {
      "code": "ATA",
      "name": "Ata Altın",
      "buyPrice": 11424.25,
      "sellPrice": 11485.75,
      "change": 1.25,
      "isPositive": true,
      "timestamp": "10:15",
    },
    {
      "code": "GÜMÜŞ",
      "name": "Gümüş",
      "buyPrice": 33.80,
      "sellPrice": 34.25,
      "change": -0.45,
      "isPositive": false,
      "timestamp": "10:15",
    },
  ];

  // Sarrafiye işçilik data
  static final List<Map<String, dynamic>> sarrafiyeData = [
    {
      'name': 'Yeni Çeyrek',
      'buyPrice': 1.6300,
      'sellPrice': 1.6350,
    },
    {
      'name': 'Eski Çeyrek',
      'buyPrice': 1.5970,
      'sellPrice': 1.6050,
    },
    {
      'name': 'Yeni Yarım',
      'buyPrice': 3.2600,
      'sellPrice': 3.2700,
    },
    {
      'name': 'Eski Yarım',
      'buyPrice': 3.1900,
      'sellPrice': 3.2050,
    },
    {
      'name': 'Yeni Tam',
      'buyPrice': 6.5000,
      'sellPrice': 6.5100,
    },
    {
      'name': 'Eski Tam',
      'buyPrice': 6.3980,
      'sellPrice': 6.4100,
    },
    {
      'name': 'Yeni Gremese',
      'buyPrice': 16.1900,
      'sellPrice': 16.2500,
    },
    {
      'name': 'Eski Gremese',
      'buyPrice': 15.9500,
      'sellPrice': 16.1000,
    },
    {
      'name': 'Yeni Ata',
      'buyPrice': 6.6000,
      'sellPrice': 6.6700,
    },
    {
      'name': 'Eski Ata',
      'buyPrice': 6.6000,
      'sellPrice': 6.6100,
    },
    {
      'name': 'Yeni Ata5',
      'buyPrice': 33.2500,
      'sellPrice': 33.3500,
    },
    {
      'name': 'Eski Ata5',
      'buyPrice': 33.1000,
      'sellPrice': 33.2000,
    },
  ];

  // Get methods
  static List<Map<String, dynamic>> getCurrencies() => currencyData;
  static List<Map<String, dynamic>> getGoldData() => goldData;
  static List<Map<String, dynamic>> getSarrafiyeData() => sarrafiyeData;

  // Update methods for real-time data
  static void updateCurrencyPrice(String code, double buyPrice, double sellPrice, double change) {
    final index = currencyData.indexWhere((currency) => currency['code'] == code);
    if (index != -1) {
      currencyData[index]['buyPrice'] = buyPrice;
      currencyData[index]['sellPrice'] = sellPrice;
      currencyData[index]['change'] = change;
      currencyData[index]['isPositive'] = change >= 0;
      currencyData[index]['timestamp'] = _getCurrentTime();
    }
  }

  static void updateGoldPrice(String code, double buyPrice, double sellPrice, double change) {
    final index = goldData.indexWhere((gold) => gold['code'] == code);
    if (index != -1) {
      goldData[index]['buyPrice'] = buyPrice;
      goldData[index]['sellPrice'] = sellPrice;
      goldData[index]['change'] = change;
      goldData[index]['isPositive'] = change >= 0;
      goldData[index]['timestamp'] = _getCurrentTime();
    }
  }

  static String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  // Simulate data refresh (for demo purposes)
  static Future<void> refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    // In real app, this would fetch from API
    // For now, just update timestamps
    for (var currency in currencyData) {
      currency['timestamp'] = _getCurrentTime();
    }
    for (var gold in goldData) {
      gold['timestamp'] = _getCurrentTime();
    }
  }
}