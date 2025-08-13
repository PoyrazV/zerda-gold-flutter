import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize based on the selected currency type
    final selectedCode = widget.selectedCurrency;
    _showingCurrencies = !_isGoldCurrency(selectedCode);
    _filteredCurrencies = _showingCurrencies ? _currencyList : _goldList;
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    final sourceList = _showingCurrencies ? _currencyList : _goldList;
    
    setState(() {
      _filteredCurrencies = sourceList.where((currency) {
        final code = (currency['code'] as String).toLowerCase();
        final name = (currency['name'] as String).toLowerCase();
        return code.contains(query) || name.contains(query);
      }).toList();
    });
  }

  void _toggleSection(bool showCurrencies) {
    if (_showingCurrencies == showCurrencies) return;
    
    setState(() {
      _showingCurrencies = showCurrencies;
      _searchController.clear(); // Clear search when switching sections
      _filteredCurrencies = _showingCurrencies ? _currencyList : _goldList;
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

          // Currency list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
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
