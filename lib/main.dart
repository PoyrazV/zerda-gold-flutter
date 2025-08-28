import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'services/notification_service.dart';
import 'services/user_data_service.dart';

// Background message handler - Forward to NotificationService handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Forward to the actual handler in NotificationService
  // This avoids duplication and ensures consistent handling
  await NotificationService.handleBackgroundMessage(message);
}

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
  
  // Initialize Firebase - No need to wait, services will handle it
  try {
    print('🔥 Initializing Firebase Core...');
    await Firebase.initializeApp();
    print('🔥 Firebase Core initialized successfully');
    
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('🔔 Background message handler registered');
  } catch (e) {
    print('❌ Firebase Core initialization failed: $e');
    // Continue without Firebase - app should still work with HTTP polling
  }
  
  // Run app immediately, initialize services in background
  runApp(
    kDebugMode
        ? DevicePreview(
            enabled: true,
            builder: (context) => MyApp(),
          )
        : MyApp(),
  );
  
  // Initialize services after app starts
  _initializeServices();
}

void _initializeServices() async {
  // Initialize auth first and wait for it
  await AuthService().initialize();
  
  // Then initialize user data service after auth is ready
  await UserDataService().initialize();
  
  // Initialize other services
  GlobalTickerService().initialize();
  FeatureConfigService().initialize();
  ThemeConfigService().initialize();
  NotificationService().initialize();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeData? _dynamicTheme;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _lastPausedTime;
  
  @override
  void initState() {
    super.initState();
    _initializeDynamicTheme();
    
    // Set navigator key for NotificationService
    NotificationService.setNavigatorKey(_navigatorKey);
    
    // Theme değişikliklerini dinle
    ThemeConfigService().addListener(_onThemeChanged);
    
    // App lifecycle observer ekle
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    ThemeConfigService().removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _lastPausedTime = DateTime.now();
        print('📱 App paused at ${_lastPausedTime}');
        break;
      case AppLifecycleState.resumed:
        if (_lastPausedTime != null) {
          final pauseDuration = DateTime.now().difference(_lastPausedTime!);
          print('📱 App resumed after ${pauseDuration.inSeconds} seconds');
          
          // If paused for more than 30 seconds, check for missed notifications
          if (pauseDuration.inSeconds > 30) {
            _checkMissedNotifications();
          }
        }
        break;
      default:
        break;
    }
  }
  
  Future<void> _checkMissedNotifications() async {
    print('🔍 Checking for missed notifications during pause...');
    
    try {
      // Reset the last notification ID to fetch recent notifications
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_notification_id');
      
      print('✅ Reset notification ID - will check for all recent notifications');
    } catch (e) {
      print('❌ Error checking missed notifications: $e');
    }
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(
          value: AuthService(),
        ),
      ],
      child: Sizer(
        builder: (context, orientation, screenType) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'zerdagold',
            locale: DevicePreview.locale(context), // Add DevicePreview locale support
            theme: _dynamicTheme ?? AppTheme.lightTheme,
            darkTheme: _dynamicTheme ?? AppTheme.darkTheme,
            themeMode: _dynamicTheme != null 
                ? (ThemeConfigService().isDarkTheme ? ThemeMode.dark : ThemeMode.light)
                : ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            // Wrap with DevicePreview.appBuilder in debug mode
            final mediaQueryChild = MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: child!,
            );
            
            return kDebugMode 
                ? DevicePreview.appBuilder(context, mediaQueryChild)
                : mediaQueryChild;
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    ),
    );
  }
}
