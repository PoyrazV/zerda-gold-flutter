import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FinancialInstrumentsListWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final percentage = item['percentageChange'] as double;
        final bool isPositive = percentage > 0;
        
        // Alternating row colors
        final Color backgroundColor = index.isEven 
            ? const Color(0xFFF0F0F0) // Darker gray for even rows
            : const Color(0xFFFFFFFF); // White for odd rows

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
                        color: const Color(0xFF1E2939),
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
                          color: const Color(0xFF6B7280),
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
                          ? const Color(0xFFECFDF5) // Green background for increase
                          : const Color(0xFFFEF2F2), // Red background for decrease
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isPositive 
                            ? const Color(0x33059669) // Green border with opacity
                            : const Color(0x1ADC2626), // Red border with opacity
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '%${percentage.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.inter(
                        fontSize: 3.5.w,
                        fontWeight: FontWeight.w600,
                        color: isPositive 
                            ? const Color(0xFF059669) // Green text
                            : const Color(0xFFDC2626), // Red text
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
