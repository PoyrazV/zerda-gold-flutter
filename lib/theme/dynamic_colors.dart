import 'package:flutter/material.dart';
import '../services/theme_config_service.dart';

/// Global extension to provide dynamic colors throughout the app
extension DynamicColors on BuildContext {
  /// Get dynamic primary color from ThemeConfigService
  Color get dynamicPrimaryColor => ThemeConfigService().primaryColor;
  
  /// Get dynamic secondary color from ThemeConfigService  
  Color get dynamicSecondaryColor => ThemeConfigService().secondaryColor;
  
  /// Get dynamic accent color from ThemeConfigService
  Color get dynamicAccentColor => ThemeConfigService().accentColor;
  
  /// Get dynamic success color from ThemeConfigService
  Color get dynamicSuccessColor => ThemeConfigService().successColor;
  
  /// Get dynamic error color from ThemeConfigService
  Color get dynamicErrorColor => ThemeConfigService().errorColor;
  
  /// Get dynamic warning color from ThemeConfigService
  Color get dynamicWarningColor => ThemeConfigService().warningColor;
  
  /// Get dynamic background color from ThemeConfigService
  Color get dynamicBackgroundColor => ThemeConfigService().backgroundColor;
  
  /// Get dynamic text color from ThemeConfigService
  Color get dynamicTextColor => ThemeConfigService().textColor;
}

/// Static helper class for commonly used dynamic colors
class DynamicThemeColors {
  static Color get primaryColor => ThemeConfigService().primaryColor;
  static Color get secondaryColor => ThemeConfigService().secondaryColor;
  static Color get accentColor => ThemeConfigService().accentColor;
  static Color get successColor => ThemeConfigService().successColor;
  static Color get errorColor => ThemeConfigService().errorColor;
  static Color get warningColor => ThemeConfigService().warningColor;
  static Color get backgroundColor => ThemeConfigService().backgroundColor;
  static Color get textColor => ThemeConfigService().textColor;
}