import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyAlertsWidget extends StatelessWidget {
  final VoidCallback onCreateAlert;

  const EmptyAlertsWidget({
    Key? key,
    required this.onCreateAlert,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          SizedBox(height: 19.h),
          CustomIconWidget(
            iconName: 'notifications_none',
            color: AppTheme.textSecondaryLight,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Alarm Kurun',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'Fiyat alarmları oluşturun',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}
