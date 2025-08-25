import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../services/gold_products_service.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../services/theme_config_service.dart';

class GoldValueCalculatorScreen extends StatefulWidget {
  const GoldValueCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<GoldValueCalculatorScreen> createState() => _GoldValueCalculatorScreenState();
}

class _GoldValueCalculatorScreenState extends State<GoldValueCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gramController = TextEditingController();
  final _milyemController = TextEditingController();
  
  double? _calculatedValue;
  double? _currentGoldPrice;
  bool _isLoading = false;
  String? _errorMessage;
  
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _fetchGoldPrice();
  }

  @override
  void dispose() {
    _gramController.dispose();
    _milyemController.dispose();
    super.dispose();
  }

  Future<void> _fetchGoldPrice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await GoldProductsService.getGoldProducts();
      
      // Find the gram gold price (usually the first active product)
      final gramGold = products.firstWhere(
        (product) => product['name'].toString().toLowerCase().contains('gram') ||
                     product['name'].toString().toLowerCase().contains('1 gr'),
        orElse: () => products.isNotEmpty ? products.first : {},
      );

      if (gramGold.isNotEmpty && gramGold['buy_price'] != null) {
        setState(() {
          _currentGoldPrice = double.tryParse(gramGold['buy_price'].toString());
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Altın fiyatı alınamadı';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fiyat bilgisi alınırken hata oluştu';
        _isLoading = false;
      });
    }
  }

  void _calculateValue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentGoldPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Güncel altın fiyatı alınamadı. Lütfen tekrar deneyin.'),
          backgroundColor: AppTheme.negativeRed,
        ),
      );
      _fetchGoldPrice();
      return;
    }

    final gram = double.tryParse(_gramController.text.replaceAll(',', '.')) ?? 0;
    final milyem = double.tryParse(_milyemController.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      // Formula: Value = (Gram * Milyem / 1000) * Current Gold Price
      _calculatedValue = (gram * milyem / 1000) * _currentGoldPrice!;
    });

    // Show success feedback
    HapticFeedback.lightImpact();
  }

  void _reset() {
    setState(() {
      _gramController.clear();
      _milyemController.clear();
      _calculatedValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ThemeConfigService().primaryColor;
    final goldColor = const Color(0xFFD4B896); // Gold color
    
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Değer Hesaplama',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Altın Değer Hesaplayıcı',
                                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  'Altınınızın gram ve milyem değerlerini girerek güncel piyasa değerini hesaplayın.',
                                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Current Gold Price Display
                    if (_currentGoldPrice != null)
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              goldColor.withValues(alpha: 0.2),
                              goldColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: goldColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Güncel Gram Altın:',
                              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _currencyFormatter.format(_currentGoldPrice),
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                color: goldColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme.negativeRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.negativeRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.negativeRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(height: 3.h),

                    // Gram Input
                    TextFormField(
                      controller: _gramController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Gram',
                        hintText: 'Altının ağırlığını girin',
                        prefixIcon: Icon(
                          Icons.scale,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        suffixText: 'gr',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.lightTheme.colorScheme.outline,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Gram değeri gereklidir';
                        }
                        final gram = double.tryParse(value.replaceAll(',', '.'));
                        if (gram == null || gram <= 0) {
                          return 'Geçerli bir gram değeri girin';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Milyem Input
                    TextFormField(
                      controller: _milyemController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Milyem (Ayar)',
                        hintText: 'Altının milyem değerini girin',
                        prefixIcon: Icon(
                          Icons.diamond,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        suffixText: '‰',
                        helperText: 'Örnek: 24 ayar = 1000, 22 ayar = 916, 18 ayar = 750',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.lightTheme.colorScheme.outline,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Milyem değeri gereklidir';
                        }
                        final milyem = double.tryParse(value.replaceAll(',', '.'));
                        if (milyem == null || milyem <= 0 || milyem > 1000) {
                          return 'Milyem değeri 1-1000 arasında olmalıdır';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Calculate Button
                    SizedBox(
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculateValue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calculate, color: Colors.white),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Hesapla',
                                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Result Display
                    if (_calculatedValue != null) ...[
                      SizedBox(height: 3.h),
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.positiveGreen.withValues(alpha: 0.1),
                              AppTheme.positiveGreen.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.positiveGreen.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Altınınızın Değeri',
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              _currencyFormatter.format(_calculatedValue),
                              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                                color: AppTheme.positiveGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildResultDetail(
                                  'Gram',
                                  _gramController.text + ' gr',
                                ),
                                _buildResultDetail(
                                  'Milyem',
                                  _milyemController.text + ' ‰',
                                ),
                                _buildResultDetail(
                                  'Birim Fiyat',
                                  _currencyFormatter.format(_currentGoldPrice),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yeni Hesaplama'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildResultDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return const CustomBottomNavigationBar(currentRoute: '/gold-value-calculator-screen');
  }
}