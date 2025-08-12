import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showMenuButton;
  final bool showBackButton;
  final double? height;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final double? textTopPadding;
  
  const AppHeader({
    Key? key,
    this.title = 'ZERDA',
    this.subtitle,
    this.actions,
    this.leading,
    this.showMenuButton = true,
    this.showBackButton = false,
    this.height,
    this.onMenuPressed,
    this.onBackPressed,
    this.textTopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 12.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading widget (menu button or custom leading)
              leading ?? (showMenuButton 
                ? Padding(
                    padding: EdgeInsets.only(top: textTopPadding ?? 0),
                    child: Builder(
                      builder: (context) => IconButton(
                        onPressed: onMenuPressed ?? () {
                          Scaffold.of(context).openDrawer();
                        },
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.all(2.w),
                      ),
                    ),
                  )
                : showBackButton
                  ? Padding(
                      padding: EdgeInsets.only(top: textTopPadding ?? 0),
                      child: IconButton(
                        onPressed: onBackPressed ?? () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.all(2.w),
                      ),
                    )
                  : SizedBox(width: 48)),

              // Title and subtitle
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: textTopPadding ?? 0),
                  child: subtitle != null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.sp,
                            letterSpacing: 1.2,
                            height: 1.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20.sp,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ),
              ),

              // Actions or placeholder
              actions?.isNotEmpty == true 
                ? Row(children: actions!)
                : showBackButton || showMenuButton 
                  ? SizedBox(width: 48)
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}