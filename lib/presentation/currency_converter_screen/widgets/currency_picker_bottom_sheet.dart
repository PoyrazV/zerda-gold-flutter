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
    {
      "code": "SEK",
      "name": "İsveç Kronu",
      "flag": "https://flagcdn.com/w320/se.png",
      "symbol": "kr"
    },
    {
      "code": "NOK",
      "name": "Norveç Kronu",
      "flag": "https://flagcdn.com/w320/no.png",
      "symbol": "kr"
    },
    {
      "code": "DKK",
      "name": "Danimarka Kronu",
      "flag": "https://flagcdn.com/w320/dk.png",
      "symbol": "kr"
    },
    {
      "code": "PLN",
      "name": "Polonya Zlotisi",
      "flag": "https://flagcdn.com/w320/pl.png",
      "symbol": "zł"
    },
    {
      "code": "CZK",
      "name": "Çek Korunası",
      "flag": "https://flagcdn.com/w320/cz.png",
      "symbol": "Kč"
    },
    {
      "code": "HUF",
      "name": "Macar Forinti",
      "flag": "https://flagcdn.com/w320/hu.png",
      "symbol": "Ft"
    },
    {
      "code": "RON",
      "name": "Rumen Leyi",
      "flag": "https://flagcdn.com/w320/ro.png",
      "symbol": "lei"
    },
    {
      "code": "BGN",
      "name": "Bulgar Levası",
      "flag": "https://flagcdn.com/w320/bg.png",
      "symbol": "лв"
    },
    {
      "code": "HRK",
      "name": "Hırvat Kunası",
      "flag": "https://flagcdn.com/w320/hr.png",
      "symbol": "kn"
    },
    {
      "code": "UAH",
      "name": "Ukrayna Grivnası",
      "flag": "https://flagcdn.com/w320/ua.png",
      "symbol": "₴"
    },
    {
      "code": "INR",
      "name": "Hindistan Rupisi",
      "flag": "https://flagcdn.com/w320/in.png",
      "symbol": "₹"
    },
    {
      "code": "KRW",
      "name": "Güney Kore Wonu",
      "flag": "https://flagcdn.com/w320/kr.png",
      "symbol": "₩"
    },
    {
      "code": "SGD",
      "name": "Singapur Doları",
      "flag": "https://flagcdn.com/w320/sg.png",
      "symbol": "S\$"
    },
    {
      "code": "HKD",
      "name": "Hong Kong Doları",
      "flag": "https://flagcdn.com/w320/hk.png",
      "symbol": "HK\$"
    },
    {
      "code": "MYR",
      "name": "Malezya Ringiti",
      "flag": "https://flagcdn.com/w320/my.png",
      "symbol": "RM"
    },
    {
      "code": "THB",
      "name": "Tayland Bahtı",
      "flag": "https://flagcdn.com/w320/th.png",
      "symbol": "฿"
    },
    {
      "code": "PHP",
      "name": "Filipinler Pesosu",
      "flag": "https://flagcdn.com/w320/ph.png",
      "symbol": "₱"
    },
    {
      "code": "IDR",
      "name": "Endonezya Rupiahı",
      "flag": "https://flagcdn.com/w320/id.png",
      "symbol": "Rp"
    },
    {
      "code": "NZD",
      "name": "Yeni Zelanda Doları",
      "flag": "https://flagcdn.com/w320/nz.png",
      "symbol": "NZ\$"
    },
    {
      "code": "ZAR",
      "name": "Güney Afrika Randı",
      "flag": "https://flagcdn.com/w320/za.png",
      "symbol": "R"
    },
    {
      "code": "BRL",
      "name": "Brezilya Reali",
      "flag": "https://flagcdn.com/w320/br.png",
      "symbol": "R\$"
    },
    {
      "code": "MXN",
      "name": "Meksika Pesosu",
      "flag": "https://flagcdn.com/w320/mx.png",
      "symbol": "Mex\$"
    },
    {
      "code": "ARS",
      "name": "Arjantin Pesosu",
      "flag": "https://flagcdn.com/w320/ar.png",
      "symbol": "\$"
    },
    {
      "code": "CLP",
      "name": "Şili Pesosu",
      "flag": "https://flagcdn.com/w320/cl.png",
      "symbol": "\$"
    },
    {
      "code": "COP",
      "name": "Kolombiya Pesosu",
      "flag": "https://flagcdn.com/w320/co.png",
      "symbol": "\$"
    },
    {
      "code": "PEN",
      "name": "Peru Solü",
      "flag": "https://flagcdn.com/w320/pe.png",
      "symbol": "S/"
    },
    {
      "code": "UYU",
      "name": "Uruguay Pesosu",
      "flag": "https://flagcdn.com/w320/uy.png",
      "symbol": "\$U"
    },
    {
      "code": "SAR",
      "name": "Suudi Arabistan Riyali",
      "flag": "https://flagcdn.com/w320/sa.png",
      "symbol": "﷼"
    },
    {
      "code": "AED",
      "name": "BAE Dirhemi",
      "flag": "https://flagcdn.com/w320/ae.png",
      "symbol": "د.إ"
    },
    {
      "code": "QAR",
      "name": "Katar Riyali",
      "flag": "https://flagcdn.com/w320/qa.png",
      "symbol": "﷼"
    },
    {
      "code": "KWD",
      "name": "Kuveyt Dinarı",
      "flag": "https://flagcdn.com/w320/kw.png",
      "symbol": "د.ك"
    },
    {
      "code": "BHD",
      "name": "Bahreyn Dinarı",
      "flag": "https://flagcdn.com/w320/bh.png",
      "symbol": ".د.ب"
    },
    {
      "code": "OMR",
      "name": "Umman Riyali",
      "flag": "https://flagcdn.com/w320/om.png",
      "symbol": "﷼"
    },
    {
      "code": "JOD",
      "name": "Ürdün Dinarı",
      "flag": "https://flagcdn.com/w320/jo.png",
      "symbol": "د.ا"
    },
    {
      "code": "LBP",
      "name": "Lübnan Lirası",
      "flag": "https://flagcdn.com/w320/lb.png",
      "symbol": "ل.ل"
    },
    {
      "code": "EGP",
      "name": "Mısır Poundu",
      "flag": "https://flagcdn.com/w320/eg.png",
      "symbol": "£"
    },
    {
      "code": "MAD",
      "name": "Fas Dirhemi",
      "flag": "https://flagcdn.com/w320/ma.png",
      "symbol": "د.م."
    },
    {
      "code": "DZD",
      "name": "Cezayir Dinarı",
      "flag": "https://flagcdn.com/w320/dz.png",
      "symbol": "د.ج"
    },
    {
      "code": "TND",
      "name": "Tunus Dinarı",
      "flag": "https://flagcdn.com/w320/tn.png",
      "symbol": "د.ت"
    },
    {
      "code": "LYD",
      "name": "Libya Dinarı",
      "flag": "https://flagcdn.com/w320/ly.png",
      "symbol": "ل.د"
    },
    {
      "code": "ISK",
      "name": "İzlanda Kronu",
      "flag": "https://flagcdn.com/w320/is.png",
      "symbol": "kr"
    },
    {
      "code": "ALL",
      "name": "Arnavutluk Leki",
      "flag": "https://flagcdn.com/w320/al.png",
      "symbol": "L"
    },
    {
      "code": "MKD",
      "name": "Kuzey Makedonya Dinarı",
      "flag": "https://flagcdn.com/w320/mk.png",
      "symbol": "ден"
    },
    {
      "code": "RSD",
      "name": "Sırbistan Dinarı",
      "flag": "https://flagcdn.com/w320/rs.png",
      "symbol": "дин."
    },
    {
      "code": "BAM",
      "name": "Bosna-Hersek Markı",
      "flag": "https://flagcdn.com/w320/ba.png",
      "symbol": "KM"
    },
    {
      "code": "AZN",
      "name": "Azerbaycan Manatı",
      "flag": "https://flagcdn.com/w320/az.png",
      "symbol": "₼"
    },
    {
      "code": "GEL",
      "name": "Gürcistan Larisi",
      "flag": "https://flagcdn.com/w320/ge.png",
      "symbol": "₾"
    },
    {
      "code": "AMD",
      "name": "Ermenistan Dramı",
      "flag": "https://flagcdn.com/w320/am.png",
      "symbol": "֏"
    },
    {
      "code": "BYN",
      "name": "Belarus Rublesi",
      "flag": "https://flagcdn.com/w320/by.png",
      "symbol": "Br"
    },
    {
      "code": "MDL",
      "name": "Moldova Leyi",
      "flag": "https://flagcdn.com/w320/md.png",
      "symbol": "L"
    },
    {
      "code": "KZT",
      "name": "Kazakistan Tengesi",
      "flag": "https://flagcdn.com/w320/kz.png",
      "symbol": "₸"
    },
    {
      "code": "UZS",
      "name": "Özbekistan Somu",
      "flag": "https://flagcdn.com/w320/uz.png",
      "symbol": "лв"
    },
    {
      "code": "KGS",
      "name": "Kırgızistan Somu",
      "flag": "https://flagcdn.com/w320/kg.png",
      "symbol": "с"
    },
    {
      "code": "TJS",
      "name": "Tacikistan Somonisi",
      "flag": "https://flagcdn.com/w320/tj.png",
      "symbol": "ЅМ"
    },
    {
      "code": "TMT",
      "name": "Türkmenistan Manatı",
      "flag": "https://flagcdn.com/w320/tm.png",
      "symbol": "m"
    },
    {
      "code": "AFN",
      "name": "Afganistan Afganisi",
      "flag": "https://flagcdn.com/w320/af.png",
      "symbol": "؋"
    },
    {
      "code": "PKR",
      "name": "Pakistan Rupisi",
      "flag": "https://flagcdn.com/w320/pk.png",
      "symbol": "₨"
    },
    {
      "code": "LKR",
      "name": "Sri Lanka Rupisi",
      "flag": "https://flagcdn.com/w320/lk.png",
      "symbol": "₨"
    },
    {
      "code": "BDT",
      "name": "Bangladeş Takası",
      "flag": "https://flagcdn.com/w320/bd.png",
      "symbol": "৳"
    },
    {
      "code": "NPR",
      "name": "Nepal Rupisi",
      "flag": "https://flagcdn.com/w320/np.png",
      "symbol": "₨"
    },
    {
      "code": "MMK",
      "name": "Myanmar Kyatı",
      "flag": "https://flagcdn.com/w320/mm.png",
      "symbol": "K"
    },
    {
      "code": "LAK",
      "name": "Laos Kipi",
      "flag": "https://flagcdn.com/w320/la.png",
      "symbol": "₭"
    },
    {
      "code": "VND",
      "name": "Vietnam Dongu",
      "flag": "https://flagcdn.com/w320/vn.png",
      "symbol": "₫"
    },
    {
      "code": "MNT",
      "name": "Moğolistan Tugrugu",
      "flag": "https://flagcdn.com/w320/mn.png",
      "symbol": "₮"
    },
    {
      "code": "ETB",
      "name": "Etiyopya Birri",
      "flag": "https://flagcdn.com/w320/et.png",
      "symbol": "Br"
    },
    {
      "code": "KES",
      "name": "Kenya Şilini",
      "flag": "https://flagcdn.com/w320/ke.png",
      "symbol": "KSh"
    },
    {
      "code": "TZS",
      "name": "Tanzanya Şilini",
      "flag": "https://flagcdn.com/w320/tz.png",
      "symbol": "TSh"
    },
    {
      "code": "UGX",
      "name": "Uganda Şilini",
      "flag": "https://flagcdn.com/w320/ug.png",
      "symbol": "USh"
    },
    {
      "code": "NGN",
      "name": "Nijerya Nairası",
      "flag": "https://flagcdn.com/w320/ng.png",
      "symbol": "₦"
    },
    {
      "code": "GHS",
      "name": "Gana Cedisi",
      "flag": "https://flagcdn.com/w320/gh.png",
      "symbol": "₵"
    },
    {
      "code": "BWP",
      "name": "Botsvana Pulası",
      "flag": "https://flagcdn.com/w320/bw.png",
      "symbol": "P"
    },
    {
      "code": "NAD",
      "name": "Namibya Doları",
      "flag": "https://flagcdn.com/w320/na.png",
      "symbol": "\$"
    },
    {
      "code": "MUR",
      "name": "Mauritius Rupisi",
      "flag": "https://flagcdn.com/w320/mu.png",
      "symbol": "₨"
    },
    {
      "code": "SCR",
      "name": "Seyşeller Rupisi",
      "flag": "https://flagcdn.com/w320/sc.png",
      "symbol": "₨"
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
    _searchController.addListener(_filterCurrencies);
    
    // Initialize with hardcoded data immediately - no API loading
    if (_showingCurrencies) {
      _filteredCurrencies = _currencyList;
    } else {
      _filteredCurrencies = _goldList;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        // No search, show full list
        _filteredCurrencies = _showingCurrencies ? _currencyList : _goldList;
      } else {
        // Search across data
        final sourceList = _showingCurrencies ? _currencyList : _goldList;
        
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
      
      if (_showingCurrencies) {
        _filteredCurrencies = _currencyList;
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


          // Currency list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency['code'] == widget.selectedCurrency;
                
                // Alternating row colors
                final Color backgroundColor = index.isEven 
                    ? const Color(0xFFF0F0F0) // Light gray for even rows
                    : const Color(0xFFFFFFFF); // White for odd rows

                return GestureDetector(
                  onTap: () {
                    widget.onCurrencySelected(currency);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1)
                          : backgroundColor,
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
                              : (currency['flag'] as String).isEmpty
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (currency['code'] as String).substring(0, (currency['code'] as String).length > 2 ? 2 : (currency['code'] as String).length),
                                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10.sp,
                                          ),
                                        ),
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
