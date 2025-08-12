import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AddPositionBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddPosition;

  const AddPositionBottomSheet({
    Key? key,
    required this.onAddPosition,
  }) : super(key: key);

  @override
  State<AddPositionBottomSheet> createState() => _AddPositionBottomSheetState();
}

class _AddPositionBottomSheetState extends State<AddPositionBottomSheet> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedAsset;
  String? _selectedAssetName;
  bool _isSearching = false;

  final List<Map<String, dynamic>> _availableAssets = [
    // Döviz kıymetleri
    {'symbol': 'USD/TRY', 'name': 'Amerikan Doları', 'type': 'currency'},
    {'symbol': 'EUR/TRY', 'name': 'Euro', 'type': 'currency'},
    {'symbol': 'GBP/TRY', 'name': 'İngiliz Sterlini', 'type': 'currency'},
    {'symbol': 'CHF/TRY', 'name': 'İsviçre Frangı', 'type': 'currency'},
    {'symbol': 'CAD/TRY', 'name': 'Kanada Doları', 'type': 'currency'},
    {'symbol': 'AUD/TRY', 'name': 'Avustralya Doları', 'type': 'currency'},
    {'symbol': 'JPY/TRY', 'name': 'Japon Yeni', 'type': 'currency'},
    {'symbol': 'SEK/TRY', 'name': 'İsveç Kronu', 'type': 'currency'},
    // Altın kıymetleri
    {'symbol': 'GRAM', 'name': 'Gram Altın', 'type': 'commodity'},
    {'symbol': 'YÇEYREK', 'name': 'Yeni Çeyrek Altın', 'type': 'commodity'},
    {'symbol': 'EÇEYREK', 'name': 'Eski Çeyrek Altın', 'type': 'commodity'},
    {'symbol': 'YYARIM', 'name': 'Yeni Yarım Altın', 'type': 'commodity'},
    {'symbol': 'EYARIM', 'name': 'Eski Yarım Altın', 'type': 'commodity'},
    {'symbol': 'YTAM', 'name': 'Yeni Tam Altın', 'type': 'commodity'},
    {'symbol': 'ETAM', 'name': 'Eski Tam Altın', 'type': 'commodity'},
    {'symbol': 'CUMHUR', 'name': 'Cumhuriyet Altını', 'type': 'commodity'},
    {'symbol': 'GUMUS', 'name': 'Gümüş (Gram)', 'type': 'commodity'},
  ];

  List<Map<String, dynamic>> get _filteredAssets {
    if (_searchController.text.isEmpty) {
      return _availableAssets;
    }
    return _availableAssets.where((asset) {
      final searchTerm = _searchController.text.toLowerCase();
      return (asset['name'] as String).toLowerCase().contains(searchTerm) ||
          (asset['symbol'] as String).toLowerCase().contains(searchTerm);
    }).toList();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Yeni Pozisyon Ekle',
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Varlık Seçin',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Varlık ara...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'search',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: CustomIconWidget(
                                  iconName: 'clear',
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      height: 25.h,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppTheme.lightTheme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _filteredAssets.length,
                        itemBuilder: (context, index) {
                          final asset = _filteredAssets[index];
                          final isSelected = _selectedAsset == asset['symbol'];

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.1),
                            leading: Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color:
                                    _getAssetTypeColor(asset['type'] as String)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: _getAssetTypeIcon(
                                      asset['type'] as String),
                                  color: _getAssetTypeColor(
                                      asset['type'] as String),
                                  size: 20,
                                ),
                              ),
                            ),
                            title: Text(
                              asset['name'] as String,
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              asset['symbol'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                            trailing: isSelected
                                ? CustomIconWidget(
                                    iconName: 'check_circle',
                                    color: AppTheme.lightTheme.primaryColor,
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedAsset = asset['symbol'] as String;
                                _selectedAssetName = asset['name'] as String;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Miktar',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: _quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Örn: 100',
                        suffixText: 'adet',
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Satın Alma Fiyatı',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Örn: 32,50',
                        prefixText: '₺ ',
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canAddPosition() ? _addPosition : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                        child: Text(
                          'Pozisyon Ekle',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAddPosition() {
    return _selectedAsset != null &&
        _quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        double.tryParse(_quantityController.text) != null &&
        double.tryParse(_priceController.text) != null;
  }

  void _addPosition() {
    final quantity = double.parse(_quantityController.text);
    final price = double.parse(_priceController.text);

    final newPosition = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'symbol': _selectedAsset!,
      'name': _selectedAssetName!,
      'quantity': quantity,
      'averageCost': price,
      'currentPrice':
          price * (0.95 + (0.1 * (DateTime.now().millisecond % 100) / 100)),
      'purchaseValue': quantity * price,
      'currentValue': quantity *
          price *
          (0.95 + (0.1 * (DateTime.now().millisecond % 100) / 100)),
      'purchaseHistory': [
        {
          'quantity': quantity,
          'price': price,
          'date':
              '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
        }
      ],
      'priceHistory': List.generate(
          30, (index) => price * (0.9 + (0.2 * (index % 10) / 10))),
    };

    widget.onAddPosition(newPosition);
    Navigator.pop(context);
  }

  Color _getAssetTypeColor(String type) {
    switch (type) {
      case 'currency':
        return AppTheme.lightTheme.primaryColor;
      case 'commodity':
        return AppTheme.alertOrange;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _getAssetTypeIcon(String type) {
    switch (type) {
      case 'currency':
        return 'currency_exchange';
      case 'commodity':
        return 'diamond';
      default:
        return 'help';
    }
  }
}
