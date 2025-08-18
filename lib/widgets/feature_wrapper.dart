import 'package:flutter/material.dart';
import '../services/feature_config_service.dart';

class FeatureWrapper extends StatelessWidget {
  final String featureName;
  final Widget child;
  final Widget? disabledFallback;
  final VoidCallback? onFeatureDisabled;

  const FeatureWrapper({
    Key? key,
    required this.featureName,
    required this.child,
    this.disabledFallback,
    this.onFeatureDisabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEnabled = FeatureConfigService().isFeatureEnabled(featureName);
    
    if (!isEnabled) {
      // Feature disable edildiğinde callback çağır
      if (onFeatureDisabled != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onFeatureDisabled!();
        });
      }
      
      // Fallback widget göster veya boş container döndür
      return disabledFallback ?? _buildDisabledFallback(context);
    }
    
    // Feature aktifse orijinal widget'ı döndür
    return child;
  }

  Widget _buildDisabledFallback(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Özellik Devre Dışı'),
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Bu Özellik Şu Anda Kullanılamıyor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Bu özellik yönetici tarafından geçici olarak devre dışı bırakılmıştır.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Geri Dön'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigation için feature-aware route guard
class FeatureGuardedRoute {
  static Route<T> createRoute<T extends Object?>(
    String featureName,
    Widget Function() builder, {
    RouteSettings? settings,
  }) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (context) => FeatureWrapper(
        featureName: featureName,
        child: builder(),
        onFeatureDisabled: () {
          // Feature disable edildiğinde ana sayfaya yönlendir
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard-screen',
            (route) => false,
          );
        },
      ),
    );
  }
}

// Bottom navigation için feature-aware item builder
class FeatureAwareBottomNavigation {
  static List<BottomNavigationBarItem> buildItems() {
    final featureConfig = FeatureConfigService();
    List<BottomNavigationBarItem> items = [];

    // Dashboard (Ana Sayfa)
    if (featureConfig.isDashboardEnabled) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.currency_exchange),
        label: 'Döviz',
      ));
    }

    // Gold Prices (Altın)
    if (featureConfig.isGoldPricesEnabled) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.monetization_on),
        label: 'Altın',
      ));
    }

    // Currency Converter (Çevirici)
    if (featureConfig.isConverterEnabled) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.swap_horiz),
        label: 'Çevirici',
      ));
    }

    // Price Alerts (Alarm)
    if (featureConfig.isAlarmsEnabled) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.notifications),
        label: 'Alarm',
      ));
    }

    // Portfolio (Portföy)
    if (featureConfig.isPortfolioEnabled) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.pie_chart),
        label: 'Portföy',
      ));
    }

    return items;
  }

  static List<String> getEnabledRoutes() {
    final featureConfig = FeatureConfigService();
    List<String> routes = [];

    if (featureConfig.isDashboardEnabled) routes.add('/dashboard-screen');
    if (featureConfig.isGoldPricesEnabled) routes.add('/gold-coin-prices-screen');
    if (featureConfig.isConverterEnabled) routes.add('/currency-converter-screen');
    if (featureConfig.isAlarmsEnabled) routes.add('/price-alerts-screen');
    if (featureConfig.isPortfolioEnabled) routes.add('/portfolio-management-screen');

    return routes;
  }
}

// Debug için feature durumu gösterici widget
class FeatureStatusDebugWidget extends StatelessWidget {
  const FeatureStatusDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final featureConfig = FeatureConfigService();
    final configInfo = featureConfig.getConfigInfo();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Feature Config Debug',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Initialized: ${configInfo['initialized']}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Total: ${configInfo['totalFeatures']}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Enabled: ${configInfo['enabledFeatures']}',
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
          Text(
            'Disabled: ${configInfo['disabledFeatures']}',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ),
    );
  }
}