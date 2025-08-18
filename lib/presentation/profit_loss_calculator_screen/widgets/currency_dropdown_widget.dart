import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CurrencyDropdownWidget extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String?>? onChanged;

  const CurrencyDropdownWidget({
    Key? key,
    required this.selectedCurrency,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Combined list of currencies and gold types (EUR as base)
    final assets = [
      // Döviz currencies
      {'code': 'USDEUR', 'name': 'USDEUR'},
      {'code': 'TRYEUR', 'name': 'TRYEUR'},
      {'code': 'GBPEUR', 'name': 'GBPEUR'},
      {'code': 'CHFEUR', 'name': 'CHFEUR'},
      {'code': 'AUDEUR', 'name': 'AUDEUR'},
      {'code': 'CADEUR', 'name': 'CADEUR'},
      {'code': 'JPYEUR', 'name': 'JPYEUR'},
      {'code': 'SEKEUR', 'name': 'SEKEUR'},
      {'code': 'NOKEUR', 'name': 'NOKEUR'},
      {'code': 'DKKEUR', 'name': 'DKKEUR'},
      {'code': 'RUBEUR', 'name': 'RUBEUR'},
      {'code': 'CNYEUR', 'name': 'CNYEUR'},
      {'code': 'KRWEUR', 'name': 'KRWEUR'},
      {'code': 'SGDEUR', 'name': 'SGDEUR'},
      {'code': 'AEDEUR', 'name': 'AEDEUR'},
      // Gold types
      {'code': 'GRAM', 'name': 'Gram Altın'},
      {'code': 'YÇEYREK', 'name': 'Yeni Çeyrek Altın'},
      {'code': 'EÇEYREK', 'name': 'Eski Çeyrek Altın'},
      {'code': 'YYARIM', 'name': 'Yeni Yarım Altın'},
      {'code': 'EYARIM', 'name': 'Eski Yarım Altın'},
      {'code': 'YTAM', 'name': 'Yeni Tam Altın'},
      {'code': 'ETAM', 'name': 'Eski Tam Altın'},
      {'code': 'YATA', 'name': 'Yeni Ata Altın'},
      {'code': 'EATA', 'name': 'Eski Ata Altın'},
      {'code': 'CUMHUR', 'name': 'Cumhuriyet Altını'},
      {'code': '22AYAR', 'name': '22 Ayar Bilezik'},
      {'code': '18AYAR', 'name': '18 Ayar Bilezik'},
      {'code': '14AYAR', 'name': '14 Ayar Bilezik'},
      {'code': 'GUMUS', 'name': 'Gümüş (Gram)'},
      {'code': 'ONSALTIN', 'name': 'Ons Altın (USD)'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kıymet Türü',
          style: TextStyle(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCurrency,
                    onChanged: onChanged,
                    isExpanded: true,
                    dropdownColor: AppTheme.lightTheme.colorScheme.surface,
                    menuMaxHeight: 300,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 4,
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    items: assets.map((asset) {
                      return DropdownMenuItem<String>(
                        value: asset['code'],
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 0.8.h),
                          child: Text(
                            asset['name']!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
