import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TimePeriodDropdownWidget extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String?>? onChanged;

  const TimePeriodDropdownWidget({
    Key? key,
    required this.selectedPeriod,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final periods = ['7 Gün', '15 Gün', '30 Gün', '60 Gün', '90 Gün'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zaman Periyodu',
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
                    value: selectedPeriod,
                    onChanged: onChanged,
                    isExpanded: true,
                    dropdownColor: AppTheme.lightTheme.colorScheme.surface,
                    menuMaxHeight: 200,
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
                    items: periods.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          child: Text('$period önce'),
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
