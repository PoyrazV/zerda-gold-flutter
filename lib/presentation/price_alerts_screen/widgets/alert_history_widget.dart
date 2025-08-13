import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AlertHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> historyAlerts;
  final Function(Map<String, dynamic>)? onDelete;

  const AlertHistoryWidget({
    Key? key,
    required this.historyAlerts,
    this.onDelete,
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
        mainAxisAlignment: MainAxisAlignment.center,
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
            textAlign: TextAlign.center,
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

    Color statusColor = Colors.grey[400]!; // Always grey for history

    double proximityPercentage =
        ((triggeredPrice - targetPrice).abs() / targetPrice * 100);

    return Dismissible(
      key: Key('history_${alert['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: AppTheme.negativeRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomIconWidget(
          iconName: 'delete',
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return true; // Always allow dismiss, confirmation will be handled by parent
      },
      onDismissed: (direction) {
        onDelete?.call(alert);
      },
        child: Container(
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
                          'Alarm Tetiklendi',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(1.5.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.lightTheme.colorScheme.primary,
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
                          'Mevcut Fiyat',
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
                ],
              ),
            ],
          ),
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
