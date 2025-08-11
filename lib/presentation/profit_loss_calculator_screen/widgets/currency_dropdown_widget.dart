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
    // Combined list of currencies and gold types
    final assets = [
      // Döviz currencies
      {'code': 'USDTRY', 'name': 'Amerikan Doları'},
      {'code': 'EURTRY', 'name': 'Euro'},
      {'code': 'GBPTRY', 'name': 'İngiliz Sterlini'},
      {'code': 'CHFTRY', 'name': 'İsviçre Frangı'},
      {'code': 'AUDTRY', 'name': 'Avustralya Doları'},
      {'code': 'CADTRY', 'name': 'Kanada Doları'},
      {'code': 'JPYTRY', 'name': 'Japon Yeni'},
      {'code': 'SEKTRY', 'name': 'İsveç Kronu'},
      {'code': 'NOKTRY', 'name': 'Norveç Kronu'},
      {'code': 'DKKTRY', 'name': 'Danimarka Kronu'},
      {'code': 'RUBTRY', 'name': 'Rus Rublesi'},
      {'code': 'CNYТRY', 'name': 'Çin Yuanı'},
      {'code': 'KRWTRY', 'name': 'Güney Kore Wonu'},
      {'code': 'SGDTRY', 'name': 'Singapur Doları'},
      {'code': 'AEDTRY', 'name': 'BAE Dirhemi'},
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
