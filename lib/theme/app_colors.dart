import 'package:flutter/material.dart';
import '../services/theme_config_service.dart';

/// Centralized color management system for the entire application
/// This class provides dynamic colors that automatically sync with admin panel changes
class AppColors {
  AppColors._();

  // ============== DYNAMIC THEME COLORS ==============
  // These colors automatically sync with ThemeConfigService
  
  /// Primary color - Main brand color used for headers, navigation, etc.
  static Color get primary => ThemeConfigService().primaryColor;
  
  /// Secondary color - Accent color used for highlights and active states  
  static Color get secondary => ThemeConfigService().secondaryColor;
  
  /// Accent color - Used for special highlights and call-to-action elements
  static Color get accent => ThemeConfigService().accentColor;
  
  /// Success color - Used for positive states, gains, confirmations
  static Color get success => ThemeConfigService().successColor;
  
  /// Error color - Used for negative states, losses, warnings
  static Color get error => ThemeConfigService().errorColor;
  
  /// Warning color - Used for alerts and caution states
  static Color get warning => ThemeConfigService().warningColor;
  
  /// Background color - Main background color
  static Color get background => ThemeConfigService().backgroundColor;
  
  /// Text color - Primary text color
  static Color get text => ThemeConfigService().textColor;

  // ============== DERIVED COLORS ==============
  // Colors derived from primary theme colors with opacity/brightness variations
  
  /// Primary color with 80% opacity for subtle backgrounds
  static Color get primaryLight => primary.withOpacity(0.8);
  
  /// Primary color with 60% opacity for even lighter backgrounds  
  static Color get primaryLighter => primary.withOpacity(0.6);
  
  /// Primary color with 20% opacity for very subtle backgrounds
  static Color get primarySubtle => primary.withOpacity(0.2);
  
  /// Secondary color with 80% opacity
  static Color get secondaryLight => secondary.withOpacity(0.8);
  
  /// Secondary color with 60% opacity
  static Color get secondaryLighter => secondary.withOpacity(0.6);
  
  /// Secondary color with 20% opacity for subtle highlights
  static Color get secondarySubtle => secondary.withOpacity(0.2);

  // ============== SPECIFIC USE CASE COLORS ==============
  
  /// Navigation bar background color
  static Color get navigationBackground => primary;
  
  /// Navigation bar active item color
  static Color get navigationActive => secondary;
  
  /// Navigation bar inactive item color
  static Color get navigationInactive => Colors.grey.shade400;
  
  /// App drawer background color
  static Color get drawerBackground => primary;
  
  /// App drawer active item color
  static Color get drawerActive => secondary;
  
  /// App drawer inactive item color
  static Color get drawerInactive => Colors.white70;
  
  /// Header background color (dashboard, screens)
  static Color get headerBackground => primary;
  
  /// Ticker section background color
  static Color get tickerBackground => primary;
  
  /// Tab bar background color
  static Color get tabBackground => primary;
  
  /// Tab bar indicator color
  static Color get tabIndicator => secondary;
  
  /// Active tab text color
  static Color get tabActiveText => secondary;
  
  /// Inactive tab text color
  static Color get tabInactiveText => Colors.white70;

  // ============== FINANCIAL DATA COLORS ==============
  
  /// Gold price color - distinctive gold color
  static Color get gold => const Color(0xFFFFD700);
  
  /// Positive change color (gains)
  static Color get positive => success;
  
  /// Negative change color (losses)  
  static Color get negative => error;
  
  /// Neutral change color
  static Color get neutral => Colors.grey.shade600;

  // ============== UI COMPONENT COLORS ==============
  
  /// Card background color
  static Color get cardBackground => Colors.white;
  
  /// Card background color for dark theme
  static Color get cardBackgroundDark => const Color(0xFF1E1E1E);
  
  /// Subtle border color
  static Color get border => Colors.grey.shade300;
  
  /// Focus border color  
  static Color get borderFocus => primary;
  
  /// Input field background
  static Color get inputBackground => Colors.grey.shade100;
  
  /// Disabled state color
  static Color get disabled => Colors.grey.shade400;
  
  /// Loading/shimmer color
  static Color get shimmer => Colors.grey.shade300;
  
  /// Shadow color
  static Color get shadow => Colors.black.withOpacity(0.1);

  // ============== STATIC COLORS ==============
  // These colors remain constant and don't change with theme
  
  /// Pure white - always white regardless of theme
  static const Color white = Colors.white;
  
  /// Pure black - always black regardless of theme
  static const Color black = Colors.black;
  
  /// Transparent - fully transparent
  static const Color transparent = Colors.transparent;
  
  /// Semi-transparent black overlay
  static final Color overlay = Colors.black.withOpacity(0.5);
  
  /// Semi-transparent white overlay
  static final Color overlayLight = Colors.white.withOpacity(0.8);

  // ============== GRADIENT COLORS ==============
  
  /// Primary gradient for backgrounds
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primary,
      primaryLight,
      primaryLighter,
    ],
  );
  
  /// Secondary gradient for accents
  static LinearGradient get secondaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      secondary,
      secondaryLight,
    ],
  );

  // ============== HELPER METHODS ==============
  
  /// Get color with specified opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Darken a color by specified amount (0.0 to 1.0)
  static Color darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
  
  /// Lighten a color by specified amount (0.0 to 1.0)
  static Color lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}

/// Extension to provide easy access to AppColors from any BuildContext
extension AppColorsExtension on BuildContext {
  /// Get AppColors reference - since AppColors is static, we return null but provide access to static methods
  AppColors? get colors => null;
  
  /// Quick access to primary color
  Color get primaryColor => AppColors.primary;
  
  /// Quick access to secondary color  
  Color get secondaryColor => AppColors.secondary;
  
  /// Quick access to accent color
  Color get accentColor => AppColors.accent;
  
  /// Quick access to success color
  Color get successColor => AppColors.success;
  
  /// Quick access to error color
  Color get errorColor => AppColors.error;
}