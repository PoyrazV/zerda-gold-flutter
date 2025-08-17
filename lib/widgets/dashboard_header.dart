import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? rightWidget;
  
  const DashboardHeader({
    Key? key,
    this.showBackButton = false,
    this.onBackPressed,
    this.rightWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 13.h, // 12-14% of screen height
      decoration: const BoxDecoration(
        color: Color(0xFF18214F), // Dark navy background
      ),
      child: SafeArea(
        top: false, // Allow content to go into status bar area
        child: Padding(
          padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 0.5.h), // Minimal top padding
          child: Row(
            children: [
              // Back button or Hamburger menu icon
              showBackButton
                ? IconButton(
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 8.w, // Responsive size
                    ),
                  )
                : Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 8.w, // Responsive size
                        ),
                      );
                    },
                  ),
              
              // ZERDA GOLD logo - responsive SVG
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/zerda-gold-logo.svg',
                    height: 5.h, // Reduced height
                    width: 25.w, // Reduced width constraint
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => SizedBox(
                      height: 5.h,
                      width: 25.w,
                    ),
                  ),
                ),
              ),
              
              // Right side - optional widget or empty space
              rightWidget ?? SizedBox(width: 12.w),
            ],
          ),
        ),
      ),
    );
  }
}