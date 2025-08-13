import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_api_service.dart';
import '../../../widgets/gold_bars_icon.dart';

class CurrencyPickerBottomSheet extends StatefulWidget {
  final String selectedCurrency;
  final Function(Map<String, dynamic>) onCurrencySelected;

  const CurrencyPickerBottomSheet({
    Key? key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  }) : super(key: key);

  @override
  State<CurrencyPickerBottomSheet> createState() =>
      _CurrencyPickerBottomSheetState();
}

class _CurrencyPickerBottomSheetState extends State<CurrencyPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCurrencies = [];
  bool _showingCurrencies = true; // true for currencies, false for gold
  
  // API Service
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  
  // API Data Storage
  List<Map<String, dynamic>> _allApiCurrencies = [];
  bool _isLoadingCurrencies = false;
  bool _isLoadingMore = false;
  int _displayedCurrencyCount = 20;

  final List<Map<String, dynamic>> _currencyList = [
    {
      "code": "USD",
      "name": "Amerikan Doları",
      "flag": "https://flagcdn.com/w320/us.png",
      "symbol": "\$"
    },
    {
      "code": "EUR",
      "name": "Euro",
      "flag": "https://flagcdn.com/w320/eu.png",
      "symbol": "€"
    },
    {
      "code": "TRY",
      "name": "Türk Lirası",
      "flag": "https://flagcdn.com/w320/tr.png",
      "symbol": "₺"
    },
    {
      "code": "GBP",
      "name": "İngiliz Sterlini",
      "flag": "https://flagcdn.com/w320/gb.png",
      "symbol": "£"
    },
    {
      "code": "JPY",
      "name": "Japon Yeni",
      "flag": "https://flagcdn.com/w320/jp.png",
      "symbol": "¥"
    },
    {
      "code": "CHF",
      "name": "İsviçre Frangı",
      "flag": "https://flagcdn.com/w320/ch.png",
      "symbol": "CHF"
    },
    {
      "code": "CAD",
      "name": "Kanada Doları",
      "flag": "https://flagcdn.com/w320/ca.png",
      "symbol": "C\$"
    },
    {
      "code": "AUD",
      "name": "Avustralya Doları",
      "flag": "https://flagcdn.com/w320/au.png",
      "symbol": "A\$"
    },
    {
      "code": "CNY",
      "name": "Çin Yuanı",
      "flag": "https://flagcdn.com/w320/cn.png",
      "symbol": "¥"
    },
    {
      "code": "RUB",
      "name": "Rus Rublesi",
      "flag": "https://flagcdn.com/w320/ru.png",
      "symbol": "₽"
    },
  ];

  final List<Map<String, dynamic>> _goldList = [
    {
      "code": "GRAM",
      "name": "Gram Altın",
      "flag": "https://cdn-icons-png.flaticon.com/512/2583/2583788.png",
      "symbol": "gr"
    },
    {
      "code": "ÇEYREK",
      "name": "Çeyrek Altın",
      "flag": "https://cdn-icons-png.flaticon.com/512/2583/2583788.png",
      "symbol": "çyr"
    },
    {
      "code": "YARIM",
      "name": "Yarım Altın",
      "flag": "https://cdn-icons-png.flaticon.com/512/2583/2583788.png",
      "symbol": "1/2"
    },
    {
      "code": "TAM",
      "name": "Tam Altın",
      "flag": "https://cdn-icons-png.flaticon.com/512/2583/2583788.png",
      "symbol": "tam"
    },
    {
      "code": "ONS",
      "name": "Ons Altın",
      "flag": "https://cdn-icons-png.flaticon.com/512/2583/2583788.png",
      "symbol": "oz"
    },
  ];

  // Get the current currency list with pagination
  List<Map<String, dynamic>> get _currentCurrencyList {
    if (_showingCurrencies) {
      // Use API data if available, otherwise fallback to hardcoded list
      final sourceList = _allApiCurrencies.isNotEmpty ? _allApiCurrencies : _currencyList;
      return sourceList.take(_displayedCurrencyCount).toList();
    } else {
      return _goldList; // Gold list doesn't need pagination (only 5 items)
    }
  }

  bool get _hasMoreCurrencies {
    if (_showingCurrencies) {
      final sourceList = _allApiCurrencies.isNotEmpty ? _allApiCurrencies : _currencyList;
      return _displayedCurrencyCount < sourceList.length;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Initialize based on the selected currency type
    final selectedCode = widget.selectedCurrency;
    _showingCurrencies = !_isGoldCurrency(selectedCode);
    _searchController.addListener(_filterCurrencies);
    
    // Load API data if showing currencies
    if (_showingCurrencies) {
      // Show fallback currencies immediately while loading API data
      _filteredCurrencies = _currencyList.take(_displayedCurrencyCount).toList();
      _loadApiCurrencies();
    } else {
      _filteredCurrencies = _goldList;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApiCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
    });

    try {
      final apiData = await _currencyApiService.getFormattedCurrencyData();
      if (mounted && apiData.isNotEmpty) {
        setState(() {
          _allApiCurrencies = _convertApiDataToCurrencyFormat(apiData);
          _filteredCurrencies = _currentCurrencyList;
        });
      }
    } catch (e) {
      print('Error loading API currencies: $e');
      // Fallback to hardcoded currencies
      if (mounted) {
        setState(() {
          _filteredCurrencies = _currencyList.take(_displayedCurrencyCount).toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrencies = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _convertApiDataToCurrencyFormat(List<Map<String, dynamic>> apiData) {
    // Currency symbols mapping
    final currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CHF': 'CHF',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CNY': '¥',
      'RUB': '₽',
      'TRY': '₺',
      'INR': '₹',
      'KRW': '₩',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'PLN': 'zł',
      'CZK': 'Kč',
      'HUF': 'Ft',
    };

    // Flag URLs mapping (using flagcdn.com)
    final flagUrls = {
      'USD': 'https://flagcdn.com/w320/us.png',
      'EUR': 'https://flagcdn.com/w320/eu.png',
      'GBP': 'https://flagcdn.com/w320/gb.png',
      'JPY': 'https://flagcdn.com/w320/jp.png',
      'CHF': 'https://flagcdn.com/w320/ch.png',
      'CAD': 'https://flagcdn.com/w320/ca.png',
      'AUD': 'https://flagcdn.com/w320/au.png',
      'CNY': 'https://flagcdn.com/w320/cn.png',
      'RUB': 'https://flagcdn.com/w320/ru.png',
      'TRY': 'https://flagcdn.com/w320/tr.png',
      'INR': 'https://flagcdn.com/w320/in.png',
      'KRW': 'https://flagcdn.com/w320/kr.png',
      'SEK': 'https://flagcdn.com/w320/se.png',
      'NOK': 'https://flagcdn.com/w320/no.png',
      'DKK': 'https://flagcdn.com/w320/dk.png',
      'PLN': 'https://flagcdn.com/w320/pl.png',
      'CZK': 'https://flagcdn.com/w320/cz.png',
      'HUF': 'https://flagcdn.com/w320/hu.png',
    };

    return apiData.map((currency) {
      final code = currency['code'] as String;
      // Extract base currency code (remove 'TRY' suffix)
      final baseCurrency = code.replaceAll('TRY', '');
      
      return {
        'code': baseCurrency,
        'name': currency['name'] as String,
        'flag': flagUrls[baseCurrency] ?? 'https://flagcdn.com/w320/us.png',
        'symbol': currencySymbols[baseCurrency] ?? baseCurrency,
      };
    }).where((currency) => currency['code'] != '').toList(); // Filter out empty codes
  }

  void _loadMoreCurrencies() {
    if (_isLoadingMore || !_hasMoreCurrencies) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          final sourceList = _allApiCurrencies.isNotEmpty ? _allApiCurrencies : _currencyList;
          _displayedCurrencyCount = (_displayedCurrencyCount + 20).clamp(0, sourceList.length);
          _filteredCurrencies = _currentCurrencyList;
          _isLoadingMore = false;
        });
      }
    });
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        // No search, show paginated list
        _filteredCurrencies = _currentCurrencyList;
      } else {
        // Search across all data (no pagination when searching)
        final sourceList = _showingCurrencies 
            ? (_allApiCurrencies.isNotEmpty ? _allApiCurrencies : _currencyList)
            : _goldList;
        
        _filteredCurrencies = sourceList.where((currency) {
          final code = (currency['code'] as String).toLowerCase();
          final name = (currency['name'] as String).toLowerCase();
          return code.contains(query) || name.contains(query);
        }).toList();
      }
    });
  }

  void _toggleSection(bool showCurrencies) {
    if (_showingCurrencies == showCurrencies) return;
    
    setState(() {
      _showingCurrencies = showCurrencies;
      _searchController.clear(); // Clear search when switching sections
      _displayedCurrencyCount = 20; // Reset pagination
      
      if (_showingCurrencies) {
        // Load API currencies if not already loaded
        if (_allApiCurrencies.isEmpty && !_isLoadingCurrencies) {
          _loadApiCurrencies();
        } else {
          _filteredCurrencies = _currentCurrencyList;
        }
      } else {
        _filteredCurrencies = _goldList;
      }
    });
  }

  bool _isGoldCurrency(String code) {
    return ['GRAM', 'ÇEYREK', 'YARIM', 'TAM', 'ONS'].contains(code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kıymet Seçin',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Toggle buttons for Döviz/Altın
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleSection(true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: _showingCurrencies 
                            ? AppTheme.lightTheme.colorScheme.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Döviz',
                        textAlign: TextAlign.center,
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _showingCurrencies
                              ? Colors.white
                              : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleSection(false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: !_showingCurrencies 
                            ? AppTheme.lightTheme.colorScheme.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Altın',
                        textAlign: TextAlign.center,
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: !_showingCurrencies
                              ? Colors.white
                              : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _showingCurrencies ? 'Döviz ara...' : 'Altın ara...',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoadingCurrencies && _showingCurrencies)
            Container(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Dövizler yükleniyor...',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

          // Currency list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _filteredCurrencies.length + (_hasMoreCurrencies && _searchController.text.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // "Daha Fazla Göster" button
                if (index == _filteredCurrencies.length && _hasMoreCurrencies && _searchController.text.isEmpty) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    child: ElevatedButton(
                      onPressed: _isLoadingMore ? null : _loadMoreCurrencies,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoadingMore
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, size: 20),
                                SizedBox(width: 2.w),
                                Text(
                                  'Daha Fazla Göster',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  );
                }
                final currency = _filteredCurrencies[index];
                final isSelected = currency['code'] == widget.selectedCurrency;

                return GestureDetector(
                  onTap: () {
                    widget.onCurrencySelected(currency);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    margin: EdgeInsets.only(bottom: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 7.w,
                          child: _isGoldCurrency(currency['code'] as String)
                              ? Center(
                                  child: GoldBarsIcon(
                                    color: const Color(0xFFFFD700), // Gold color
                                    size: 32,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CustomImageWidget(
                                    imageUrl: currency['flag'] as String,
                                    width: 10.w,
                                    height: 7.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency['code'] as String,
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme
                                          .lightTheme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                currency['name'] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currency['symbol'] as String,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
