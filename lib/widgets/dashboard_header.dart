import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_export.dart';
import '../theme/app_colors.dart';
import '../services/theme_config_service.dart';

class DashboardHeader extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? rightWidget;
  final double? customTopPadding;
  
  const DashboardHeader({
    Key? key,
    this.showBackButton = false,
    this.onBackPressed,
    this.rightWidget,
    this.customTopPadding,
  }) : super(key: key);

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {

  @override
  void initState() {
    super.initState();
    ThemeConfigService().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeConfigService().removeListener(_onThemeChanged);
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
    return Container(
      height: 13.h, // 12-14% of screen height
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
      ),
      child: SafeArea(
        top: false, // Allow content to go into status bar area
        child: Padding(
          padding: EdgeInsets.only(left: 4.w, right: 4.w, top: widget.customTopPadding ?? 0.5.h), // Custom or default padding
          child: Row(
            children: [
              // Back button or Hamburger menu icon
              widget.showBackButton
                ? IconButton(
                    onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
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
              widget.rightWidget ?? SizedBox(width: 12.w),
            ],
          ),
        ),
      ),
    );
  }
}