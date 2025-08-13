import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userProfileImage;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userProfileImage => _userProfileImage;

  // Initialize auth state from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userEmail = prefs.getString('userEmail');
    _userName = prefs.getString('userName');
    _userProfileImage = prefs.getString('userProfileImage');
    notifyListeners();
  }

  // Login method
  Future<bool> login({
    required String email,
    required String password,
    String? userName,
    String? profileImage,
  }) async {
    try {
      // TODO: Implement actual authentication logic here
      // For now, accept any email/password combination
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', userName ?? email.split('@')[0]);
      if (profileImage != null) {
        await prefs.setString('userProfileImage', profileImage);
      }

      _isLoggedIn = true;
      _userEmail = email;
      _userName = userName ?? email.split('@')[0];
      _userProfileImage = profileImage;
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _userProfileImage = null;
    
    notifyListeners();
  }

  // Mock login for testing
  Future<void> mockLogin() async {
    await login(
      email: 'demo@zerda.com',
      password: 'demo123',
      userName: 'Demo User',
    );
  }
}