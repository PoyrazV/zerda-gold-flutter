# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Zerda Gold** is a Flutter-based financial tracking application focused on currency exchange rates, gold prices, and portfolio management. The app follows a professional minimalist design with dark theme support.

## Development Commands

### Basic Commands
- **Install dependencies**: `flutter pub get`
- **Run the app**: `flutter run`
- **Build for Android**: `flutter build apk --release`
- **Build for iOS**: `flutter build ios --release`

### Code Quality
- **Lint check**: Uses `flutter_lints: ^5.0.0` for code quality
- No custom analysis_options.yaml file - follows default Flutter linting rules

## Architecture Overview

### Project Structure
```
lib/
├── core/                    # Core utilities and exports
│   └── app_export.dart      # Central export file for common imports
├── presentation/            # UI screens organized by feature
│   ├── dashboard_screen/    # Main currency exchange screen
│   ├── currency_converter_screen/
│   ├── portfolio_management_screen/
│   └── [other_screens]/
├── routes/                  # Application routing
│   └── app_routes.dart      # Centralized route definitions
├── theme/                   # Theme configuration
│   └── app_theme.dart       # Light/dark theme definitions
├── widgets/                 # Reusable UI components
└── main.dart               # Application entry point
```

### Key Architecture Patterns
- **Screen-based organization**: Each screen has its own folder with widgets subfolder
- **Centralized theming**: Professional financial theme with color-coded data (green/red for gains/losses)
- **Responsive design**: Uses Sizer package for screen adaptation
- **Mock data architecture**: Currently uses hardcoded mock data for development

## Critical Configuration Rules

### Asset Management
- **ONLY use existing asset directories**: `assets/` and `assets/images/`
- **DO NOT add new asset directories** (svg/, icons/, etc.)
- **Use Google Fonts instead of local fonts** - no fonts section in pubspec.yaml

### Dependencies
- **Core dependencies marked as CRITICAL in pubspec.yaml** - DO NOT remove:
  - `sizer: ^2.0.15` (responsive design)
  - `flutter_svg: ^2.0.9` (SVG support) 
  - `google_fonts: ^6.1.0` (typography)
  - `shared_preferences: ^2.2.2` (local storage)

### App Configuration
- **Portrait-only orientation** enforced in main.dart
- **Custom error widget** implementation required
- **Text scaling locked** to 1.0 for consistent UI

## Theme System

### Design Philosophy
- **Professional financial minimalism** with deep blue primary colors
- **Data-focused typography** using Inter font family
- **Color-coded financial data**: Green for gains, red for losses, orange for alerts
- **Monospace fonts** (Roboto Mono) for precise data display

### Theme Usage
```dart
// Access current theme
ThemeData theme = Theme.of(context);

// Financial data colors
Color positiveColor = AppTheme.positiveGreen;
Color negativeColor = AppTheme.negativeRed;

// Data-specific text styles
TextStyle dataStyle = AppTheme.dataTextStyle(isLight: true);
TextStyle priceChangeStyle = AppTheme.priceChangeTextStyle(
  isLight: true, 
  isPositive: true
);
```

## Navigation System

- **Centralized routing** in `AppRoutes` class
- **Named routes** with constants for type safety
- **Bottom navigation** structure with 5 main sections:
  - Döviz (Currency Exchange) - Main screen
  - Altın (Gold) - Asset details
  - Çevirici (Converter) - Currency conversion
  - Alarm (Alerts) - Price notifications
  - Portföy (Portfolio) - Portfolio management

## Environment Configuration

- **Environment variables** stored in `env.json` (not committed)
- **API keys** for Supabase, OpenAI, Gemini, Anthropic, Perplexity
- **Update env.json** with real credentials for API functionality

## Data Management

- Currently uses **mock data** in screen components
- **Mock currency data** includes buy/sell prices, changes, timestamps
- **Real-time simulation** with refresh functionality
- Ready for integration with real financial APIs

## Common Development Patterns

### Screen Component Structure
```dart
class ExampleScreen extends StatefulWidget {
  // Animation controllers for smooth interactions
  // Mock data definitions for development
  // State management for UI updates
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Responsive design using Sizer (w, h extensions)
      // Theme-aware styling
      // Professional financial UI components
    );
  }
}
```

### Responsive Design
- Use Sizer extensions: `50.w` (50% width), `20.h` (20% height)
- All sizing should be relative to screen dimensions
- Consistent padding/margin using percentage-based values

## Testing

- **Flutter test framework** available via `flutter_test` SDK
- Currently no specific test files - ready for test implementation
- Use standard Flutter testing patterns for widget and integration tests