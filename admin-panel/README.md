# Zerda Admin Panel

Mobil uygulama özelliklerini yönetmek için web tabanlı admin paneli.

## Kurulum

1. Node.js dependencies'leri yükle:
```bash
npm install
```

2. Server'ı başlat:
```bash
npm start
```

3. Admin panel'e eriş: http://localhost:3001

## API Endpoints

### Configuration
- `GET /api/config` - Mevcut konfigürasyonu al
- `POST /api/config` - Konfigürasyonu güncelle
- `GET /api/features` - Sadece feature durumlarını al
- `POST /api/features/:featureName` - Tek feature güncelle

### Management
- `GET /api/stats` - Feature istatistikleri
- `POST /api/reset` - Varsayılan ayarlara dön
- `GET /health` - Health check

## Kullanım

1. **Web Panel**: Ana sayfadan feature'ları açıp kapatabilirsiniz
2. **JSON Export**: Ayarları JSON olarak indirebilirsiniz
3. **Mobile Integration**: Flutter uygulaması otomatik olarak bu ayarları kullanır

## Feature Flags

- `dashboard` - Ana sayfa (Döviz kurları)
- `goldPrices` - Altın fiyatları
- `converter` - Döviz çevirici
- `alarms` - Alarm sistemi
- `portfolio` - Portföy yönetimi
- `profile` - Profil ayarları
- `notifications` - Bildirimler
- `darkMode` - Koyu tema
- `offlineMode` - Çevrimdışı mod
- `charts` - Grafik görünümü

## Flutter Entegrasyonu

Flutter uygulaması şu adresten konfigürasyonu alır:
- `http://localhost:3001/api/features`

## Config Dosyası

Ayarlar `zerda-config.json` dosyasında saklanır ve server restart'ta korunur.