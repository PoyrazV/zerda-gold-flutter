import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ScreenHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onMenuTap;

  const ScreenHeaderWidget({
    Key? key,
    required this.title,
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
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Hamburger menu icon
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
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
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
