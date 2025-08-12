import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _loadingOpacityAnimation;

  bool _isInitializing = true;
  String _loadingText = 'Initializing...';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Loading animation controller
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation with bounce effect
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Loading indicator opacity animation
    _loadingOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeIn,
    ));

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Start loading animation after logo appears
      await Future.delayed(const Duration(milliseconds: 800));
      _loadingAnimationController.forward();

      // Step 1: Check authentication status
      await _updateLoadingState('Checking authentication...', 0.2);
      await Future.delayed(const Duration(milliseconds: 500));
      final bool isAuthenticated = await _checkAuthenticationStatus();

      // Step 2: Load user preferences
      await _updateLoadingState('Loading preferences...', 0.4);
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadUserPreferences();

      // Step 3: Fetch market data configuration
      await _updateLoadingState('Fetching market data...', 0.6);
      await Future.delayed(const Duration(milliseconds: 600));
      await _fetchMarketDataConfiguration();

      // Step 4: Prepare cached data
      await _updateLoadingState('Preparing data...', 0.8);
      await Future.delayed(const Duration(milliseconds: 400));
      await _prepareCachedData();

      // Step 5: Complete initialization
      await _updateLoadingState('Ready!', 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate based on authentication status
      if (mounted) {
        _navigateToNextScreen(isAuthenticated);
      }
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        _handleInitializationError();
      }
    }
  }

  Future<void> _updateLoadingState(String text, double progress) async {
    if (mounted) {
      setState(() {
        _loadingText = text;
        _loadingProgress = progress;
      });
    }
  }

  Future<bool> _checkAuthenticationStatus() async {
    // Simulate authentication check
    // In real implementation, check SharedPreferences or secure storage
    return false; // Default to not authenticated for demo
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences
    // In real implementation, load from SharedPreferences
  }

  Future<void> _fetchMarketDataConfiguration() async {
    // Simulate fetching market configuration
    // In real implementation, make API call to get supported currencies, etc.
  }

  Future<void> _prepareCachedData() async {
    // Simulate preparing cached price data
    // In real implementation, load cached data for offline access
  }

  void _navigateToNextScreen(bool isAuthenticated) {
    // Auto-login as admin - everyone opens as admin
    Navigator.pushReplacementNamed(context, '/dashboard-screen');
  }

  void _handleInitializationError() {
    // Show retry option after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _showRetryDialog();
      }
    });
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          title: Text(
            'Connection Error',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Unable to initialize the app. Please check your internet connection and try again.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryInitialization();
              },
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _retryInitialization() {
    setState(() {
      _isInitializing = true;
      _loadingText = 'Initializing...';
      _loadingProgress = 0.0;
    });
    _logoAnimationController.reset();
    _loadingAnimationController.reset();
    _setupAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.colorScheme.primary,
                AppTheme.lightTheme.colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Spacer to push content to center
                const Spacer(flex: 2),

                // Animated Logo Section
                AnimatedBuilder(
                  animation: _logoAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: _buildAppLogo(),
                      ),
                    );
                  },
                ),

                SizedBox(height: 4.h),

                // Loading Section
                AnimatedBuilder(
                  animation: _loadingAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loadingOpacityAnimation.value,
                      child: _buildLoadingSection(),
                    );
                  },
                ),

                // Spacer to balance layout
                const Spacer(flex: 3),

                // App Version and Copyright
                _buildFooterSection(),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Column(
      children: [
        // App Icon/Logo
        Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Z',
              style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 48.sp,
              ),
            ),
          ),
        ),

        SizedBox(height: 3.h),

        // App Name
        Text(
          'ZERDA',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 24.sp,
          ),
        ),

        SizedBox(height: 1.h),

        // App Tagline
        Text(
          'Professional Financial Tracking',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onPrimary
                .withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        // Loading Progress Bar
        Container(
          width: 60.w,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.onPrimary
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _loadingProgress,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Loading Text
        Text(
          _loadingText,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onPrimary
                .withValues(alpha: 0.9),
            letterSpacing: 0.3,
          ),
        ),

        SizedBox(height: 1.h),

        // Loading Percentage
        Text(
          '${(_loadingProgress * 100).toInt()}%',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onPrimary
                .withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        // Company Name
        RichText(
          text: TextSpan(
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary
                  .withValues(alpha: 0.9),
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: 'COSMOS IT'),
              TextSpan(
                text: '+',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 1.h),

        // Credit Line
        Text(
          'COSMOS IT+ tarafından hazırlanmıştır.',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onPrimary
                .withValues(alpha: 0.7),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}
