import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CreateAlertBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreateAlert;

  const CreateAlertBottomSheet({
    Key? key,
    required this.onCreateAlert,
  }) : super(key: key);

  @override
  State<CreateAlertBottomSheet> createState() => _CreateAlertBottomSheetState();
}

class _CreateAlertBottomSheetState extends State<CreateAlertBottomSheet> {
  final TextEditingController _targetPriceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedAsset = 'USD/TRY';
  String _selectedAssetName = 'Amerikan Doları';
  String _alertType = 'above';
  String _selectedSound = 'default';
  bool _enableNotification = true;

  final List<Map<String, dynamic>> _availableAssets = [
    // Döviz kıymetleri
    {'symbol': 'USD/TRY', 'name': 'Amerikan Doları', 'currentPrice': 34.2156},
    {'symbol': 'EUR/TRY', 'name': 'Euro', 'currentPrice': 37.1234},
    {'symbol': 'GBP/TRY', 'name': 'İngiliz Sterlini', 'currentPrice': 43.5678},
    {'symbol': 'CHF/TRY', 'name': 'İsviçre Frangı', 'currentPrice': 38.4567},
    {'symbol': 'CAD/TRY', 'name': 'Kanada Doları', 'currentPrice': 25.3456},
    {'symbol': 'AUD/TRY', 'name': 'Avustralya Doları', 'currentPrice': 22.7890},
    {'symbol': 'JPY/TRY', 'name': 'Japon Yeni', 'currentPrice': 0.2345},
    {'symbol': 'SEK/TRY', 'name': 'İsveç Kronu', 'currentPrice': 3.2156},
    {'symbol': 'NOK/TRY', 'name': 'Norveç Kronu', 'currentPrice': 3.1234},
    {'symbol': 'DKK/TRY', 'name': 'Danimarka Kronu', 'currentPrice': 4.9876},
    
    // Altın kıymetleri
    {'symbol': 'GRAM', 'name': 'Gram Altın', 'currentPrice': 2847.50},
    {'symbol': 'YÇEYREK', 'name': 'Yeni Çeyrek Altın', 'currentPrice': 5024.75},
    {'symbol': 'EÇEYREK', 'name': 'Eski Çeyrek Altın', 'currentPrice': 4987.25},
    {'symbol': 'YYARIM', 'name': 'Yeni Yarım Altın', 'currentPrice': 10125.50},
    {'symbol': 'EYARIM', 'name': 'Eski Yarım Altın', 'currentPrice': 10087.75},
    {'symbol': 'YTAM', 'name': 'Yeni Tam Altın', 'currentPrice': 20345.25},
    {'symbol': 'ETAM', 'name': 'Eski Tam Altın', 'currentPrice': 20289.50},
    {'symbol': 'CUMHUR', 'name': 'Cumhuriyet Altını', 'currentPrice': 33456.75},
    {'symbol': 'GUMUS', 'name': 'Gümüş (Gram)', 'currentPrice': 36.89},
  ];

  final List<Map<String, String>> _soundOptions = [
    {'value': 'default', 'name': 'Varsayılan'},
    {'value': 'bell', 'name': 'Zil Sesi'},
    {'value': 'chime', 'name': 'Melodi'},
    {'value': 'alert', 'name': 'Uyarı Sesi'},
    {'value': 'silent', 'name': 'Sessiz'},
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
    _targetPriceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAssetSelector(),
                  SizedBox(height: 2.5.h),
                  _buildAlertTypeSelector(),
                  SizedBox(height: 2.5.h),
                  _buildTargetPriceInput(),
                  SizedBox(height: 2.5.h),
                  _buildNotificationSettings(),
                  SizedBox(height: 2.5.h),
                  _buildSoundSelector(),
                  SizedBox(height: 3.h),
                  _buildCreateButton(),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.textSecondaryLight,
              size: 24,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'Yeni Alarm Oluştur',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Varlık Seçin',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Varlık ara...',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'search',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        SizedBox(height: 1.h),
        Container(
          height: 20.h,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            itemCount: _filteredAssets.length,
            itemBuilder: (context, index) {
              final asset = _filteredAssets[index];
              final isSelected = _selectedAsset == asset['symbol'];

              return ListTile(
                selected: isSelected,
                selectedTileColor: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                leading: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: _getAssetTypeColor(asset['symbol'] as String)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: _getAssetTypeIcon(asset['symbol'] as String),
                      color: _getAssetTypeColor(asset['symbol'] as String),
                      size: 20,
                    ),
                  ),
                ),
                title: Text(
                  asset['name'] as String,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
                subtitle: Text(
                  asset['symbol'] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.sp,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.formatTRY(asset['currentPrice'] as double, decimalPlaces: 4),
                      style: AppTheme.dataTextStyle(
                        isLight: true,
                        fontSize: 12.sp,
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
      ],
    );
  }

  Widget _buildAlertTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alarm Türü',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _alertType = 'above'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: _alertType == 'above'
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    border: Border.all(
                      color: _alertType == 'above'
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.dividerLight,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: 'trending_up',
                        color: _alertType == 'above'
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.textSecondaryLight,
                        size: 24,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Fiyat Üstü',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: _alertType == 'above'
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _alertType = 'below'),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: _alertType == 'below'
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    border: Border.all(
                      color: _alertType == 'below'
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.dividerLight,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: 'trending_down',
                        color: _alertType == 'below'
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.textSecondaryLight,
                        size: 24,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Fiyat Altı',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: _alertType == 'below'
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetPriceInput() {
    final selectedAssetData = _availableAssets.firstWhere(
      (asset) => asset['symbol'] == _selectedAsset,
    );
    final double currentPrice =
        (selectedAssetData['currentPrice'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hedef Fiyat',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Mevcut fiyat: ${CurrencyFormatter.formatTRY(currentPrice, decimalPlaces: 4)}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _targetPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
          ],
          decoration: InputDecoration(
            hintText: 'Hedef fiyatı girin',
            prefixText: '₺ ',
            prefixStyle: AppTheme.dataTextStyle(
              isLight: true,
              fontSize: 16.sp,
            ),
          ),
          style: AppTheme.dataTextStyle(
            isLight: true,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bildirim Ayarları',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'notifications',
                color: _enableNotification
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.textSecondaryLight,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Bildirimi',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      'Alarm tetiklendiğinde bildirim gönder',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enableNotification,
                onChanged: (value) =>
                    setState(() => _enableNotification = value),
                activeColor: AppTheme.lightTheme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoundSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bildirim Sesi',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSound,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              items: _soundOptions.map((sound) {
                return DropdownMenuItem<String>(
                  value: sound['value']!,
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: sound['value'] == 'silent'
                            ? 'volume_off'
                            : 'volume_up',
                        color: AppTheme.textSecondaryLight,
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        sound['name']!,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSound = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _createAlert,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Alarm Oluştur',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  void _createAlert() {
    if (_targetPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen hedef fiyat girin'),
          backgroundColor: AppTheme.negativeRed,
        ),
      );
      return;
    }

    final double? targetPrice = double.tryParse(_targetPriceController.text);
    if (targetPrice == null || targetPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen geçerli bir fiyat girin'),
          backgroundColor: AppTheme.negativeRed,
        ),
      );
      return;
    }

    final selectedAssetData = _availableAssets.firstWhere(
      (asset) => asset['symbol'] == _selectedAsset,
    );

    final alertData = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'assetName': _selectedAsset,
      'assetFullName': _selectedAssetName,
      'targetPrice': targetPrice,
      'currentPrice': selectedAssetData['currentPrice'],
      'alertType': _alertType,
      'status': 'active',
      'isEnabled': true,
      'enableNotification': _enableNotification,
      'soundType': _selectedSound,
      'createdAt': DateTime.now(),
    };

    widget.onCreateAlert(alertData);
    Navigator.pop(context);
  }

  Color _getAssetTypeColor(String symbol) {
    // Altın kıymetleri
    if (symbol.contains('GRAM') || 
        symbol.contains('ÇEYREK') || 
        symbol.contains('YARIM') || 
        symbol.contains('TAM') || 
        symbol.contains('CUMHUR') || 
        symbol.contains('GUMUS')) {
      return AppTheme.alertOrange;
    }
    // Döviz kıymetleri
    return AppTheme.lightTheme.colorScheme.primary;
  }

  String _getAssetTypeIcon(String symbol) {
    // Altın kıymetleri
    if (symbol.contains('GRAM') || 
        symbol.contains('ÇEYREK') || 
        symbol.contains('YARIM') || 
        symbol.contains('TAM') || 
        symbol.contains('CUMHUR') || 
        symbol.contains('GUMUS')) {
      return 'diamond';
    }
    // Döviz kıymetleri
    return 'currency_exchange';
  }
}
