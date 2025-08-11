import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class HeaderWidget extends StatelessWidget {
  final VoidCallback onMenuTap;

  const HeaderWidget({
    Key? key,
    required this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.h,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark navy background
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menu button (hamburger)
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

              // ZERDA title
              Text(
                'ZERDA',
                style: TextStyle(
                  color: const Color(0xFFFFFFFF),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              // Empty space to center the title
              SizedBox(width: 48), // Same width as menu button
            ],
          ),
        ),
      ),
    );
  }
}
