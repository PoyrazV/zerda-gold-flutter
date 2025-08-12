import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PositionCard extends StatefulWidget {
  final Map<String, dynamic> position;
  final VoidCallback onEdit;
  final VoidCallback onSetTarget;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onPriceAlert;

  const PositionCard({
    Key? key,
    required this.position,
    required this.onEdit,
    required this.onSetTarget,
    required this.onRemove,
    required this.onDuplicate,
    required this.onExport,
    required this.onPriceAlert,
  }) : super(key: key);

  @override
  State<PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends State<PositionCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double currentValue =
        (widget.position['currentValue'] as num).toDouble();
    final double purchaseValue =
        (widget.position['purchaseValue'] as num).toDouble();
    final double gainLoss = currentValue - purchaseValue;
    final double gainLossPercentage = (gainLoss / purchaseValue) * 100;
    final bool isPositive = gainLoss >= 0;

    return GestureDetector(
      onTap: _toggleExpanded,
      onLongPress: () => _showContextMenu(context),
      child: Dismissible(
        key: Key(widget.position['id'].toString()),
        background: _buildSwipeBackground(true),
        secondaryBackground: _buildSwipeBackground(false),
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right actions
            _showQuickActions(context);
          } else {
            // Swipe left actions
            _showDetailedBreakdown(context);
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          (widget.position['symbol'] as String)
                              .substring(0, 2)
                              .toUpperCase(),
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.position['name'] as String,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${widget.position['quantity']} adet',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatTRY(currentValue),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName:
                                  isPositive ? 'trending_up' : 'trending_down',
                              color: isPositive
                                  ? AppTheme.positiveGreen
                                  : AppTheme.negativeRed,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              CurrencyFormatter.formatPercentageChange(gainLossPercentage),
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: isPositive
                                    ? AppTheme.positiveGreen
                                    : AppTheme.negativeRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: _isExpanded ? 'expand_less' : 'expand_more',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildExpandedContent(
                    gainLoss, gainLossPercentage, isPositive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeftSwipe) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isLeftSwipe
            ? AppTheme.lightTheme.primaryColor
            : AppTheme.alertOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: isLeftSwipe ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: isLeftSwipe ? 'edit' : 'info',
                color: Colors.white,
                size: 24,
              ),
              SizedBox(height: 1.h),
              Text(
                isLeftSwipe ? 'Düzenle' : 'Detaylar',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
      double gainLoss, double gainLossPercentage, bool isPositive) {
    final List<FlSpot> chartData = (widget.position['priceHistory'] as List)
        .asMap()
        .entries
        .map((entry) =>
            FlSpot(entry.key.toDouble(), (entry.value as num).toDouble()))
        .toList();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 20.h,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: isPositive
                        ? AppTheme.positiveGreen
                        : AppTheme.negativeRed,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (isPositive
                              ? AppTheme.positiveGreen
                              : AppTheme.negativeRed)
                          .withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Ortalama Maliyet',
                  CurrencyFormatter.formatTRY((widget.position['averageCost'] as num).toDouble()),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Gerçekleşmemiş K/Z',
                  CurrencyFormatter.formatTRY(gainLoss),
                  color: isPositive
                      ? AppTheme.positiveGreen
                      : AppTheme.negativeRed,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Güncel Fiyat',
                  CurrencyFormatter.formatTRY((widget.position['currentPrice'] as num).toDouble()),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Toplam Getiri',
                  CurrencyFormatter.formatPercentageChange(gainLossPercentage),
                  color: isPositive
                      ? AppTheme.positiveGreen
                      : AppTheme.negativeRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            color: color ?? AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Miktarı Düzenle'),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'flag',
                color: AppTheme.alertOrange,
                size: 24,
              ),
              title: const Text('Hedef Fiyat Belirle'),
              onTap: () {
                Navigator.pop(context);
                widget.onSetTarget();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.negativeRed,
                size: 24,
              ),
              title: const Text('Pozisyonu Kaldır'),
              onTap: () {
                Navigator.pop(context);
                widget.onRemove();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Satın Alma Geçmişi',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount:
                      (widget.position['purchaseHistory'] as List).length,
                  itemBuilder: (context, index) {
                    final purchase = (widget.position['purchaseHistory']
                        as List)[index] as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${purchase['quantity']} adet',
                                    style: AppTheme
                                        .lightTheme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    purchase['date'] as String,
                                    style:
                                        AppTheme.lightTheme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatTRY((purchase['price'] as num).toDouble()),
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Kopyala'),
              onTap: () {
                Navigator.pop(context);
                widget.onDuplicate();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Veriyi Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                widget.onExport();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'notifications',
                color: AppTheme.alertOrange,
                size: 24,
              ),
              title: const Text('Fiyat Alarmı'),
              onTap: () {
                Navigator.pop(context);
                widget.onPriceAlert();
              },
            ),
          ],
        ),
      ),
    );
  }
}