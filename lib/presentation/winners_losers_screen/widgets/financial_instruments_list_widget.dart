import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../services/theme_config_service.dart';

class FinancialInstrumentsListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final bool isWinners;
  final VoidCallback onRefresh;

  const FinancialInstrumentsListWidget({
    Key? key,
    required this.data,
    required this.isWinners,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<FinancialInstrumentsListWidget> createState() => _FinancialInstrumentsListWidgetState();
}

class _FinancialInstrumentsListWidgetState extends State<FinancialInstrumentsListWidget> {
  final ThemeConfigService _themeConfigService = ThemeConfigService();

  @override
  void initState() {
    super.initState();
    _themeConfigService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeConfigService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild with new theme colors
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.data.length,
      itemBuilder: (context, index) {
        final item = widget.data[index];
        final percentage = item['percentageChange'] as double;
        final bool isPositive = percentage > 0;
        
        // Alternating row colors from theme
        final Color backgroundColor = index.isEven 
            ? _themeConfigService.listRowEven
            : _themeConfigService.listRowOdd;

        return Container(
          height: 8.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.w),
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left section - Instrument name and description
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 4.w,
                        fontWeight: FontWeight.w800,
                        color: _themeConfigService.listNameText,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item['description'] != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        item['description'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 3.w,
                          fontWeight: FontWeight.normal,
                          color: _themeConfigService.listTimeText,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Right section - Percentage change with Dashboard style
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: isPositive 
                          ? _themeConfigService.listPrimaryColor
                          : _themeConfigService.listSecondaryColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isPositive 
                            ? _themeConfigService.listPrimaryBorder.withOpacity(0.2)
                            : _themeConfigService.listSecondaryBorder.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '%${percentage.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.inter(
                        fontSize: 3.5.w,
                        fontWeight: FontWeight.w600,
                        color: isPositive 
                            ? _themeConfigService.listPrimaryText
                            : _themeConfigService.listSecondaryText,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
