import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'services/auth_service.dart';
import 'services/global_ticker_service.dart';
import 'services/watchlist_service.dart';

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
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'fintracker_pro',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
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
