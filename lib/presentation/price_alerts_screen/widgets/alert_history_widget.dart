import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AlertHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> historyAlerts;

  const AlertHistoryWidget({
    Key? key,
    required this.historyAlerts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (historyAlerts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyAlerts.length,
          itemBuilder: (context, index) {
            final alert = historyAlerts[index];
            return _buildHistoryCard(alert);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'history',
            color: AppTheme.textSecondaryLight,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Henüz Geçmiş Alarm Yok',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Tetiklenen alarmlar burada görünecek',
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

  Widget _buildHistoryCard(Map<String, dynamic> alert) {
    final String assetName = alert['assetName'] as String;
    final String assetFullName = alert['assetFullName'] as String;
    final double targetPrice = (alert['targetPrice'] as num).toDouble();
    final double triggeredPrice = (alert['triggeredPrice'] as num).toDouble();
    final DateTime triggeredAt = alert['triggeredAt'] as DateTime;
    final String alertType = alert['alertType'] as String;
    final String status = alert['status'] as String;

    final bool isSuccessful = alertType == 'above'
        ? triggeredPrice >= targetPrice
        : triggeredPrice <= targetPrice;

    Color statusColor = isSuccessful
        ? AppTheme.lightTheme.colorScheme.primary
        : AppTheme.alertOrange;

    double proximityPercentage =
        ((triggeredPrice - targetPrice).abs() / targetPrice * 100);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 2.5.w,
                          height: 2.5.w,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.5.w),
                        Expanded(
                          child: Text(
                            assetName,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      isSuccessful ? 'Başarıyla Tetiklendi' : 'Kısmi Tetiklendi',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: isSuccessful ? 'check_circle' : 'warning',
                  color: statusColor,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hedef Fiyat',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      CurrencyFormatter.formatTRY(targetPrice, decimalPlaces: 4),
                      style: AppTheme.dataTextStyle(
                        isLight: true,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tetiklenen Fiyat',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      CurrencyFormatter.formatTRY(triggeredPrice, decimalPlaces: 4),
                      style: AppTheme.dataTextStyle(
                        isLight: true,
                        fontSize: 12.sp,
                      ).copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sapma',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    CurrencyFormatter.formatPercentage(proximityPercentage, decimalPlaces: 1),
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: proximityPercentage < 5
                          ? AppTheme.alertOrange
                          : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              CustomIconWidget(
                iconName:
                    alertType == 'above' ? 'trending_up' : 'trending_down',
                color: alertType == 'above'
                    ? AppTheme.positiveGreen
                    : AppTheme.negativeRed,
                size: 16,
              ),
              SizedBox(width: 1.5.w),
              Text(
                alertType == 'above'
                    ? 'Fiyat Üstü Alarmı'
                    : 'Fiyat Altı Alarmı',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontSize: 12.sp,
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(triggeredAt),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
}
