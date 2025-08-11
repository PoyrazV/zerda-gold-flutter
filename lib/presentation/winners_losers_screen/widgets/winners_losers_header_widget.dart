import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class WinnersLosersHeaderWidget extends StatelessWidget {
  final VoidCallback onMenuTap;

  const WinnersLosersHeaderWidget({
    Key? key,
    required this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2.h,
        left: 4.w,
        right: 4.w,
        bottom: 2.h,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Row(
        children: [
          // Hamburger menu
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: Icon(
                Icons.menu,
                color: const Color(0xFFFFFFFF),
                size: 24,
              ),
            ),
          ),

          // Centered title
          Expanded(
            child: Center(
              child: Text(
                'Kazananlar Kaybedenler',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFFFFF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),

          // Spacer to balance the hamburger menu
          SizedBox(width: 8.w),
        ],
      ),
    );
  }
}
