import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/app_logo_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/social_login_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Remove mock credentials - use real backend
  // Backend test users:
  // demo@zerda.com (password: demo123)
  // test@zerda.com (password: test123)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.lightTheme.scaffoldBackgroundColor,
                  AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 8.h),

                      // App Logo Section
                      const AppLogoWidget(),

                      SizedBox(height: 6.h),

                      // Welcome Text
                      Text(
                        'Hoş Geldiniz',
                        textAlign: TextAlign.center,
                        style: AppTheme.lightTheme.textTheme.headlineMedium
                            ?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 1.h),

                      Text(
                        'Hesabınıza giriş yapın ve finansal piyasaları takip etmeye başlayın',
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Error Message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.error
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.error
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'error',
                                color: AppTheme.lightTheme.colorScheme.error,
                                size: 5.w,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // Login Form
                      LoginFormWidget(
                        onLogin: _handleLogin,
                        isLoading: _isLoading,
                      ),

                      SizedBox(height: 4.h),

                      // Social Login
                      SocialLoginWidget(
                        isLoading: _isLoading,
                        onSocialLogin: _handleSocialLogin,
                      ),

                      const Spacer(),

                      // Register Link
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Yeni kullanıcı? ',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 2.w),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Kayıt Ol',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                ),
                // Back Button
                Positioned(
                  top: 2.h,
                  left: 4.w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 24,
                      ),
                      padding: EdgeInsets.all(2.w),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call real backend authentication
      final success = await AuthService().login(
        email: email,
        password: password,
      );
      
      if (success) {
        // Success haptic feedback
        HapticFeedback.lightImpact();

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard-screen');
        }
      } else {
        setState(() {
          _errorMessage = 'Geçersiz e-posta veya şifre. Lütfen tekrar deneyin.';
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Giriş yapılırken bir hata oluştu. Lütfen tekrar deneyin.';
      });
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate social login process
      await Future.delayed(const Duration(seconds: 2));

      // Update AuthService with successful social login
      await AuthService().login(
        email: 'social@$provider.com',
        password: 'social123',
        userName: '$provider User',
      );

      // Success haptic feedback
      HapticFeedback.lightImpact();

      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard-screen');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '$provider ile giriş yapılırken bir hata oluştu.';
      });
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleRegister() {
    Navigator.pushNamed(context, '/register-screen');
  }
}
