import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/gold_bars_icon.dart';

class CurrencySelectorWidget extends StatelessWidget {
  final String currencyCode;
  final String flagUrl;
  final VoidCallback onTap;

  const CurrencySelectorWidget({
    Key? key,
    required this.currencyCode,
    required this.flagUrl,
    required this.onTap,
  }) : super(key: key);

  bool _isGoldCurrency(String code) {
    return ['GRAM', 'ÇEYREK', 'YARIM', 'TAM', 'ONS'].contains(code);
  }
  
  String _getDisplayCode(String code) {
    // Shorten gold currency names to 3 letters
    switch (code) {
      case 'GRAM':
        return 'GRM';
      case 'ÇEYREK':
        return 'ÇYR';
      case 'YARIM':
        return 'YRM';
      case 'TAM':
        return 'TAM';
      case 'ONS':
        return 'ONS';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.w,
              height: 4.w,
              child: _isGoldCurrency(currencyCode)
                  ? Center(
                      child: GoldBarsIcon(
                        color: const Color(0xFFFFD700), // Gold color
                        size: 22,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CustomImageWidget(
                        imageUrl: flagUrl,
                        width: 6.w,
                        height: 4.w,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            SizedBox(width: 2.w),
            Text(
              _getDisplayCode(currencyCode),
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 1.w),
            CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
