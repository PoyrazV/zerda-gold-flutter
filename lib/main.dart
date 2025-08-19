import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
    );
  };
  
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Run app immediately, initialize services in background
  runApp(MyApp());
  
  // Initialize services after app starts
  AuthService().initialize();
  GlobalTickerService().initialize();
  FeatureConfigService().initialize();
  ThemeConfigService().initialize();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData? _dynamicTheme;
  
  @override
  void initState() {
    super.initState();
    _initializeDynamicTheme();
    
    // Theme değişikliklerini dinle
    ThemeConfigService().addListener(_onThemeChanged);
  }
  
  @override
  void dispose() {
    ThemeConfigService().removeListener(_onThemeChanged);
    super.dispose();
  }
  
  Future<void> _initializeDynamicTheme() async {
    // ThemeConfigService'in hazır olmasını bekle
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _dynamicTheme = ThemeConfigService().createThemeData();
      });
    }
  }
  
  void _onThemeChanged() {
    print('🎨 Main app received theme change notification!');
    if (mounted) {
      setState(() {
        _dynamicTheme = ThemeConfigService().createThemeData();
      });
      print('🎨 App theme updated dynamically! New primary color: ${ThemeConfigService().primaryColor}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'fintracker_pro',
          theme: _dynamicTheme ?? AppTheme.lightTheme,
          darkTheme: _dynamicTheme ?? AppTheme.darkTheme,
          themeMode: _dynamicTheme != null 
              ? (ThemeConfigService().isDarkTheme ? ThemeMode.dark : ThemeMode.light)
              : ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
