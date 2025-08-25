import 'package:flutter/material.dart';
import '../presentation/asset_detail_screen/asset_detail_screen.dart';
import '../presentation/price_alerts_screen/price_alerts_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/currency_converter_screen/currency_converter_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/portfolio_management_screen/portfolio_management_screen.dart';
import '../presentation/currency_exchange_screen/currency_exchange_screen.dart';
import '../presentation/profit_loss_calculator_screen/profit_loss_calculator_screen.dart';
import '../presentation/winners_losers_screen/winners_losers_screen.dart';
import '../presentation/gold_coin_prices_screen/gold_coin_prices_screen.dart';
import '../presentation/watchlist_screen/watchlist_screen.dart';
import '../presentation/sarrafiye_iscilik_screen/sarrafiye_iscilik_screen.dart';
import '../presentation/gecmis_kurlar_screen/gecmis_kurlar_screen.dart';
import '../presentation/add_asset_screen/add_asset_screen.dart';
import '../presentation/asset_selection_screen/asset_selection_screen.dart';
import '../presentation/register_screen/register_screen.dart';
import '../presentation/edit_profile_screen/edit_profile_screen.dart';
import '../presentation/change_password_screen/change_password_screen.dart';
import '../presentation/email_preferences_screen/email_preferences_screen.dart';
import '../presentation/gold_value_calculator_screen/gold_value_calculator_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String assetDetail = '/asset-detail-screen';
  static const String priceAlerts = '/price-alerts-screen';
  static const String dashboard = '/dashboard-screen';
  static const String splash = '/splash-screen';
  static const String userProfile = '/user-profile-screen';
  static const String currencyConverter = '/currency-converter-screen';
  static const String login = '/login-screen';
  static const String portfolioManagement = '/portfolio-management-screen';
  static const String currencyExchange = '/currency-exchange-screen';
  static const String profitLossCalculator = '/profit-loss-calculator-screen';
  static const String winnersLosers = '/winners-losers-screen';
  static const String goldCoinPrices = '/gold-coin-prices-screen';
  static const String watchlist = '/watchlist-screen';
  static const String sarrafiyeIscilik = '/sarrafiye-iscilik-screen';
  static const String gecmisKurlar = '/gecmis-kurlar-screen';
  static const String addAsset = '/add-asset-screen';
  static const String assetSelection = '/asset-selection-screen';
  static const String register = '/register-screen';
  static const String editProfile = '/edit-profile-screen';
  static const String changePassword = '/change-password-screen';
  static const String emailPreferences = '/email-preferences-screen';
  static const String goldValueCalculator = '/gold-value-calculator-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    assetDetail: (context) => const AssetDetailScreen(),
    priceAlerts: (context) => const PriceAlertsScreen(),
    dashboard: (context) => const DashboardScreen(),
    splash: (context) => const SplashScreen(),
    userProfile: (context) => const UserProfileScreen(),
    currencyConverter: (context) => const CurrencyConverterScreen(),
    login: (context) => const LoginScreen(),
    portfolioManagement: (context) => const PortfolioManagementScreen(),
    currencyExchange: (context) => const CurrencyExchangeScreen(),
    profitLossCalculator: (context) => const ProfitLossCalculatorScreen(),
    winnersLosers: (context) => const WinnersLosersScreen(),
    goldCoinPrices: (context) => const GoldCoinPricesScreen(),
    watchlist: (context) => const WatchlistScreen(),
    sarrafiyeIscilik: (context) => const SarrafiyeIscilikScreen(),
    gecmisKurlar: (context) => const GecmisKurlarScreen(),
    addAsset: (context) => const AddAssetScreen(),
    assetSelection: (context) => const AssetSelectionScreen(),
    register: (context) => const RegisterScreen(),
    editProfile: (context) => const EditProfileScreen(),
    changePassword: (context) => const ChangePasswordScreen(),
    emailPreferences: (context) => const EmailPreferencesScreen(),
    goldValueCalculator: (context) => const GoldValueCalculatorScreen(),
  };
}
