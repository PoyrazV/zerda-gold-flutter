class MockData {
  // Currency exchange rates data
  static const List<Map<String, dynamic>> currencies = [
    {
      "code": "USD/TRY",
      "name": "Amerikan Doları",
      "buyPrice": 34.2156,
      "sellPrice": 34.2389,
      "change": 0.0234,
      "changePercent": 0.068,
      "isPositive": true,
    },
    {
      "code": "EUR/TRY", 
      "name": "Euro",
      "buyPrice": 37.1234,
      "sellPrice": 37.1567,
      "change": -0.0456,
      "changePercent": -0.123,
      "isPositive": false,
    },
    {
      "code": "GBP/TRY",
      "name": "İngiliz Sterlini", 
      "buyPrice": 43.5678,
      "sellPrice": 43.6112,
      "change": 0.1234,
      "changePercent": 0.284,
      "isPositive": true,
    },
    {
      "code": "CHF/TRY",
      "name": "İsviçre Frangı",
      "buyPrice": 38.9876,
      "sellPrice": 39.0123,
      "change": -0.0567,
      "changePercent": -0.145,
      "isPositive": false,
    },
    {
      "code": "CAD/TRY",
      "name": "Kanada Doları",
      "buyPrice": 25.4321,
      "sellPrice": 25.4654,
      "change": 0.0789,
      "changePercent": 0.312,
      "isPositive": true,
    },
    {
      "code": "AUD/TRY",
      "name": "Avustralya Doları", 
      "buyPrice": 22.7890,
      "sellPrice": 22.8123,
      "change": -0.0234,
      "changePercent": -0.103,
      "isPositive": false,
    },
    {
      "code": "JPY/TRY",
      "name": "Japon Yeni",
      "buyPrice": 0.2345,
      "sellPrice": 0.2356,
      "change": 0.0012,
      "changePercent": 0.513,
      "isPositive": true,
    },
  ];

  // Gold prices data
  static const List<Map<String, dynamic>> goldPrices = [
    {
      "code": "GRAM",
      "name": "Gram Altın",
      "buyPrice": 2847.50,
      "sellPrice": 2849.20,
      "change": -12.50,
      "changePercent": -0.437,
      "isPositive": false,
    },
    {
      "code": "YÇEYREK",
      "name": "Yeni Çeyrek Altın",
      "buyPrice": 2891.75,
      "sellPrice": 2893.45,
      "change": 15.25,
      "changePercent": 0.531,
      "isPositive": true,
    },
    {
      "code": "EÇEYREK", 
      "name": "Eski Çeyrek Altın",
      "buyPrice": 2860.40,
      "sellPrice": 2862.10,
      "change": -8.60,
      "changePercent": -0.300,
      "isPositive": false,
    },
    {
      "code": "YYARIM",
      "name": "Yeni Yarım Altın",
      "buyPrice": 5783.50,
      "sellPrice": 5786.90,
      "change": 30.50,
      "changePercent": 0.531,
      "isPositive": true,
    },
    {
      "code": "EYARIM",
      "name": "Eski Yarım Altın", 
      "buyPrice": 5720.80,
      "sellPrice": 5724.20,
      "change": -17.20,
      "changePercent": -0.300,
      "isPositive": false,
    },
    {
      "code": "YTAM",
      "name": "Yeni Tam Altın",
      "buyPrice": 11567.00,
      "sellPrice": 11573.80,
      "change": 61.00,
      "changePercent": 0.531,
      "isPositive": true,
    },
    {
      "code": "ETAM", 
      "name": "Eski Tam Altın",
      "buyPrice": 11441.60,
      "sellPrice": 11448.40,
      "change": -34.40,
      "changePercent": -0.300,
      "isPositive": false,
    },
  ];

  // Default ticker data (when watchlist is empty)
  static const List<Map<String, dynamic>> defaultTickerData = [
    {
      'symbol': 'USD/TRY',
      'price': 34.2156,
      'change': 0.0234,
      'changePercent': 0.068
    },
    {
      'symbol': 'EUR/TRY',
      'price': 37.1234,
      'change': -0.0456,
      'changePercent': -0.123
    },
    {
      'symbol': 'GBP/TRY',
      'price': 43.5678,
      'change': 0.1234,
      'changePercent': 0.284
    },
    {
      'symbol': 'GOLD',
      'price': 2847.50,
      'change': -12.50,
      'changePercent': -0.437
    },
  ];

  // Winners data for winners/losers screen
  static const List<Map<String, dynamic>> winnersData = [
    {
      "name": "ALTIN/USD",
      "absoluteChange": "+12.50",
      "percentageChange": 8.45,
      "isPositive": true,
    },
    {
      "name": "GÜMÜŞ/USD",
      "absoluteChange": "+2.30", 
      "percentageChange": 6.21,
      "isPositive": true,
    },
    {
      "name": "BAKIR/USD",
      "absoluteChange": "+0.85",
      "percentageChange": 4.15,
      "isPositive": true,
    },
    {
      "name": "EUR/USD",
      "absoluteChange": "+0.012",
      "percentageChange": 3.76,
      "isPositive": true,
    },
    {
      "name": "GBP/USD",
      "absoluteChange": "+0.021",
      "percentageChange": 2.89,
      "isPositive": true,
    },
  ];

  // Losers data for winners/losers screen
  static const List<Map<String, dynamic>> losersData = [
    {
      "name": "PLATIN/USD",
      "absoluteChange": "-3.100",
      "percentageChange": -7.68,
      "isPositive": false,
    },
    {
      "name": "GÜMÜŞ ONS",
      "absoluteChange": "-97,00",
      "percentageChange": -5.23,
      "isPositive": false,
    },
    {
      "name": "PETROL",
      "absoluteChange": "-2.45",
      "percentageChange": -4.12,
      "isPositive": false,
    },
    {
      "name": "GAZ NATURAL",
      "absoluteChange": "-0.89", 
      "percentageChange": -3.67,
      "isPositive": false,
    },
    {
      "name": "USD/TRY",
      "absoluteChange": "-0.156",
      "percentageChange": -2.94,
      "isPositive": false,
    },
  ];

  // Historical currency data for gecmis kurlar screen
  static const Map<String, List<Map<String, dynamic>>> historicalData = {
    'DOVIZ': [
      {
        'code': 'USDTRY',
        'buyPrice': 40.503,
        'sellPrice': 40.596,
      },
      {
        'code': 'EURTRY',
        'buyPrice': 46.096,
        'sellPrice': 46.285,
      },
      {
        'code': 'EURUSD',
        'buyPrice': 1.1381,
        'sellPrice': 1.1401,
      },
      {
        'code': 'GBPTRY',
        'buyPrice': 53.258,
        'sellPrice': 53.655,
      },
      {
        'code': 'CHFTRY',
        'buyPrice': 49.190,
        'sellPrice': 49.707,
      },
      {
        'code': 'AUDTRY',
        'buyPrice': 25.246,
        'sellPrice': 26.042,
      },
      {
        'code': 'CADTRY',
        'buyPrice': 28.752,
        'sellPrice': 29.589,
      },
      {
        'code': 'SARTRY',
        'buyPrice': 10.645,
        'sellPrice': 10.972,
      },
      {
        'code': 'JPYTRY',
        'buyPrice': 0.2670,
        'sellPrice': 0.2710,
      },
    ],
    'ALTIN': [
      {
        'code': 'GRAM',
        'buyPrice': 2847.50,
        'sellPrice': 2849.20,
      },
      {
        'code': 'YÇEYREK',
        'buyPrice': 2891.75,
        'sellPrice': 2893.45,
      },
      {
        'code': 'EÇEYREK',
        'buyPrice': 2860.40,
        'sellPrice': 2862.10,
      },
      {
        'code': 'YYARIM',
        'buyPrice': 5783.50,
        'sellPrice': 5786.90,
      },
      {
        'code': 'EYARIM',
        'buyPrice': 5720.80,
        'sellPrice': 5724.20,
      },
      {
        'code': 'YTAM',
        'buyPrice': 11567.00,
        'sellPrice': 11573.80,
      },
      {
        'code': 'ETAM',
        'buyPrice': 11441.60,
        'sellPrice': 11448.40,
      },
    ],
  };

  // Portfolio assets (limited to currency and gold only)
  static const List<Map<String, dynamic>> portfolioAssets = [
    {
      'name': 'USD',
      'type': 'currency',
      'color': '0xFF4CAF50',
      'icon': 'dollar'
    },
    {
      'name': 'EUR',
      'type': 'currency', 
      'color': '0xFF2196F3',
      'icon': 'euro'
    },
    {
      'name': 'GBP',
      'type': 'currency',
      'color': '0xFFFF5722',
      'icon': 'pound'
    },
    {
      'name': 'CHF',
      'type': 'currency',
      'color': '0xFF9C27B0',
      'icon': 'franc'
    },
    {
      'name': 'GRAM ALTIN',
      'type': 'gold',
      'color': '0xFFFFD700',
      'icon': 'gold'
    },
    {
      'name': 'ÇEYREK ALTIN',
      'type': 'gold',
      'color': '0xFFFFD700', 
      'icon': 'gold'
    },
    {
      'name': 'YARIM ALTIN',
      'type': 'gold',
      'color': '0xFFFFD700',
      'icon': 'gold'
    },
    {
      'name': 'TAM ALTIN',
      'type': 'gold',
      'color': '0xFFFFD700',
      'icon': 'gold'
    },
  ];

  // Sarrafiye iscilik rates
  static const List<Map<String, dynamic>> sarrafiyeRates = [
    {
      'name': 'Gram Altın',
      'workmanshipRate': 125.00,
      'buyRate': 2847.50,
      'sellRate': 2849.20,
    },
    {
      'name': 'Çeyrek Altın',
      'workmanshipRate': 150.00,
      'buyRate': 2891.75,
      'sellRate': 2893.45,
    },
    {
      'name': 'Yarım Altın',
      'workmanshipRate': 200.00,
      'buyRate': 5783.50,
      'sellRate': 5786.90,
    },
    {
      'name': 'Tam Altın',
      'workmanshipRate': 300.00,
      'buyRate': 11567.00,
      'sellRate': 11573.80,
    },
  ];

  // Time periods for various filters
  static const List<String> timePeriods = [
    '30 Gün',
    '60 Gün', 
    '90 Gün',
    '6 Ay',
    '1 Yıl',
    '2 Yıl',
    '5 Yıl'
  ];

  // Winners/Losers timeframes
  static const List<String> winnersLosersTimeframes = [
    "GÜN",
    "HAFTA",
    "AY", 
    "6 AY",
    "YIL",
    "5 YIL",
    "MAX"
  ];

  // Currency codes for profit/loss calculator
  static const List<String> calculatorCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'CHF',
    'CAD',
    'AUD',
    'JPY'
  ];
}