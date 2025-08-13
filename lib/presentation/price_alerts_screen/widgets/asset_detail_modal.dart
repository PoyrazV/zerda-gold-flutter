import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AssetDetailModal extends StatefulWidget {
  final Map<String, dynamic> selectedAsset;
  final Function(Map<String, dynamic>, double) onCreateAlarm;

  const AssetDetailModal({
    Key? key,
    required this.selectedAsset,
    required this.onCreateAlarm,
  }) : super(key: key);

  @override
  State<AssetDetailModal> createState() => _AssetDetailModalState();
}

class _AssetDetailModalState extends State<AssetDetailModal> {
  double _targetPrice = 0.0;
  final List<double> _percentageOptions = [-5, -2, -1, 1, 2, 5];
  double? _selectedPercentage;
  final TextEditingController _priceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _targetPrice = widget.selectedAsset['currentPrice'] as double;
    _priceController.text = '₺${_targetPrice.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  _buildTargetPriceSection(),
                  SizedBox(height: 4.h),
                  _buildPercentageButtons(),
                  SizedBox(height: 6.h),
                  _buildInfoText(),
                  SizedBox(height: 4.h),
                  _buildCreateAlarmButton(),
                  SizedBox(height: 4.h),
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
      height: 8.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.all(2.w),
              ),

              // Asset code
              Text(
                widget.selectedAsset['code'] as String,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.sp,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space for symmetry
              SizedBox(width: 12.w),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTargetPriceSection() {
    return Column(
      children: [
        Text(
          'Hedef Fiyat',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // Direct editable target price
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: TextField(
            controller: _priceController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 3,
                ),
              ),
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
              contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
              hintText: '₺0,00',
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 28.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            onChanged: (value) {
              // Parse the price when user types
              final cleanValue = value.replaceAll('₺', '').replaceAll(',', '.');
              final newPrice = double.tryParse(cleanValue);
              if (newPrice != null && newPrice > 0) {
                setState(() {
                  _targetPrice = newPrice;
                  _selectedPercentage = null; // Clear percentage selection when manually edited
                });
              }
            },
            inputFormatters: [
              // Allow only numbers, dots, commas, and ₺ symbol
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,₺]')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageButtons() {
    return Row(
      children: _percentageOptions.map((percentage) {
        final isSelected = _selectedPercentage == percentage;
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 0.5.w),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedPercentage = percentage;
                  final basePrice = widget.selectedAsset['currentPrice'] as double;
                  _targetPrice = basePrice * (1 + (percentage / 100));
                  _priceController.text = '₺${_targetPrice.toStringAsFixed(2)}';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected 
                    ? AppTheme.lightTheme.colorScheme.primary
                    : Colors.grey[200],
                foregroundColor: isSelected 
                    ? Colors.white 
                    : AppTheme.textSecondaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: isSelected ? 2 : 0,
                side: BorderSide(
                  color: isSelected 
                      ? AppTheme.lightTheme.colorScheme.primary
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Text(
                '${percentage > 0 ? '+' : ''}${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoText() {
    final assetCode = widget.selectedAsset['code'] as String;
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        '$assetCode fiyatı her ${CurrencyFormatter.formatTRY(_targetPrice, decimalPlaces: 2)} olduğunda haberdar ol',
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCreateAlarmButton() {
    return Container(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton(
        onPressed: () {
          widget.onCreateAlarm(widget.selectedAsset, _targetPrice);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
        child: Text(
          'ALARM EKLE',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

}