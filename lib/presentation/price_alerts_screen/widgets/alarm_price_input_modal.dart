import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AlarmPriceInputModal extends StatefulWidget {
  final Map<String, dynamic> selectedAsset;
  final Function(Map<String, dynamic>) onCreateAlert;

  const AlarmPriceInputModal({
    Key? key,
    required this.selectedAsset,
    required this.onCreateAlert,
  }) : super(key: key);

  @override
  State<AlarmPriceInputModal> createState() => _AlarmPriceInputModalState();
}

class _AlarmPriceInputModalState extends State<AlarmPriceInputModal> {
  final TextEditingController _targetPriceController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus price input when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _priceFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 3.h),
            _buildAssetInfo(),
            SizedBox(height: 3.h),
            _buildTargetPriceInput(),
            SizedBox(height: 4.h),
            _buildCreateButton(),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            'Hedef Fiyat Belirle',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: _getAssetIcon(widget.selectedAsset['code'] as String),
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedAsset['code'] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  widget.selectedAsset['name'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Mevcut Fiyat',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 10.sp,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                CurrencyFormatter.formatEUR(widget.selectedAsset['currentPrice'] as double, decimalPlaces: 4),
                style: AppTheme.dataTextStyle(
                  isLight: true,
                  fontSize: 14.sp,
                ).copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPriceInput() {
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
        SizedBox(height: 1.5.h),
        TextFormField(
          controller: _targetPriceController,
          focusNode: _priceFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
          ],
          decoration: InputDecoration(
            hintText: 'Hedef fiyatı girin',
            prefixText: '€ ',
            prefixStyle: AppTheme.dataTextStyle(
              isLight: true,
              fontSize: 18.sp,
            ).copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          ),
          style: AppTheme.dataTextStyle(
            isLight: true,
            fontSize: 18.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
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
                  'Fiyat bu seviyeye ulaştığında size bildirim gönderilecek',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
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
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final alertData = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'assetName': widget.selectedAsset['code'],
      'assetFullName': widget.selectedAsset['name'],
      'targetPrice': targetPrice,
      'currentPrice': widget.selectedAsset['currentPrice'],
      'alertType': 'above', // Default to above since we removed the selector
      'status': 'active',
      'isEnabled': true,
      'enableNotification': true, // Default to true since we removed the option
      'soundType': 'default', // Default sound since we removed the selector
      'createdAt': DateTime.now(),
    };

    widget.onCreateAlert(alertData);
    Navigator.pop(context);
  }

  String _getAssetIcon(String assetCode) {
    // Gold assets
    if (assetCode.contains('GRAM') || 
        assetCode.contains('ÇEYREK') || 
        assetCode.contains('YARIM') || 
        assetCode.contains('TAM') || 
        assetCode.contains('CUMHUR') || 
        assetCode.contains('GUMUS')) {
      return 'diamond';
    }
    // Currency assets
    return 'currency_exchange';
  }
}