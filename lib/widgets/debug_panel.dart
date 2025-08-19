import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/app_export.dart';

class DebugPanel extends StatefulWidget {
  @override
  _DebugPanelState createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  String _lastResult = 'Henüz test yapılmadı';
  bool _loading = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 DEBUG PANEL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          
          Text('Son Test Sonucu:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _lastResult,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          
          SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _testFeatureService,
                icon: Icon(Icons.settings),
                label: Text('Test Features'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              
              ElevatedButton.icon(
                onPressed: _loading ? null : _testThemeService,
                icon: Icon(Icons.palette),
                label: Text('Test Theme'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
              
              ElevatedButton.icon(
                onPressed: _loading ? null : _testDirectAPI,
                icon: Icon(Icons.api),
                label: Text('Test API'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              
              ElevatedButton.icon(
                onPressed: _loading ? null : _forceSync,
                icon: Icon(Icons.sync),
                label: Text('Force Sync'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
          
          if (_loading)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
  
  Future<void> _testFeatureService() async {
    setState(() { _loading = true; });
    
    try {
      final service = FeatureConfigService();
      final features = service.getAllFeatures();
      final info = service.getConfigInfo();
      
      setState(() {
        _lastResult = '✅ FeatureService OK\n'
                     'Initialized: ${info['initialized']}\n'
                     'Features: ${features.length}\n'
                     'Data: $features';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ FeatureService Error: $e';
      });
    }
    
    setState(() { _loading = false; });
  }
  
  Future<void> _testThemeService() async {
    setState(() { _loading = true; });
    
    try {
      final service = ThemeConfigService();
      final info = service.getThemeInfo();
      
      // Mevcut renkler
      final primaryColor = service.primaryColor.value.toRadixString(16).padLeft(8, '0');
      final secondaryColor = service.secondaryColor.value.toRadixString(16).padLeft(8, '0');
      
      setState(() {
        _lastResult = '✅ ThemeService OK\n'
                     'Initialized: ${info['initialized']}\n'
                     'Customer: ${info['customerId']}\n'
                     'Theme: ${info['themeType']}\n'
                     'Primary: #${primaryColor.substring(2).toUpperCase()}\n'
                     'Secondary: #${secondaryColor.substring(2).toUpperCase()}\n'
                     'Font: ${info['fontFamily']}\n'
                     'Config: ${info['config']}';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ ThemeService Error: $e';
      });
    }
    
    setState(() { _loading = false; });
  }
  
  Future<void> _testDirectAPI() async {
    setState(() { _loading = true; });
    
    try {
      // Manuel API çağrısı
      final dio = Dio();
      final response = await dio.get('http://10.0.2.2:3009/api/features');
      
      setState(() {
        _lastResult = '✅ Direct API OK\n'
                     'Status: ${response.statusCode}\n'
                     'Data: ${response.data}';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ Direct API Error: $e';
      });
    }
    
    setState(() { _loading = false; });
  }
  
  Future<void> _forceSync() async {
    setState(() { _loading = true; });
    
    try {
      final featureSuccess = await FeatureConfigService().syncNow();
      final themeSuccess = await ThemeConfigService().syncNow();
      
      // Theme info'yu al
      final themeInfo = ThemeConfigService().getThemeInfo();
      
      setState(() {
        _lastResult = '🔄 Force Sync Result\n'
                     'Features: ${featureSuccess ? '✅' : '❌'}\n'
                     'Theme: ${themeSuccess ? '✅' : '❌'}\n'
                     'Primary Color: ${themeInfo['primaryColor']}\n'
                     'Font: ${themeInfo['fontFamily']}';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ Force Sync Error: $e';
      });
    }
    
    setState(() { _loading = false; });
  }
}