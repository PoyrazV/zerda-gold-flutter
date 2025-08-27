// Feature display names (Türkçe isimler)
export const featureDisplayNames = {
    dashboard: 'Döviz',
    goldPrices: 'Altın', 
    converter: 'Çevirici',
    alarms: 'Alarmlar',
    portfolio: 'Portföy',
    profile: 'Profil',
    watchlist: 'Takip Listem',
    profitLossCalculator: 'Kar/Zarar Hesaplama',
    performanceHistory: 'Performans Geçmişi',
    sarrafiyeIscilik: 'Sarrafiye İşçilikleri',
    gecmisKurlar: 'Geçmiş Kurlar'
};

// Feature order for display
export const featureOrder = [
    'dashboard', 
    'goldPrices', 
    'converter', 
    'alarms', 
    'portfolio', 
    'profile', 
    'watchlist', 
    'profitLossCalculator', 
    'performanceHistory', 
    'sarrafiyeIscilik', 
    'gecmisKurlar'
];

// Feature descriptions
export const featureDescriptions = {
    dashboard: 'Ana sayfa - Genel bakış ve istatistikler',
    goldPrices: 'Altın fiyatları ve piyasa verileri',
    converter: 'Döviz çevirici araçları',
    alarms: 'Fiyat alarm ve bildirimleri',
    portfolio: 'Portföy yönetimi ve takibi',
    profile: 'Kullanıcı profil ayarları',
    watchlist: 'Favori dövizler izleme listesi',
    profitLossCalculator: 'Kâr/zarar hesaplama araçları',
    performanceHistory: 'Geçmiş performans analizi',
    sarrafiyeIscilik: 'Sarrafiye işçilik hesaplaması',
    gecmisKurlar: 'Geçmiş kurlar ve trend analizi'
};

// Tab configurations  
export const tabs = {
    dashboard: { icon: 'fas fa-chart-bar', label: 'Ana Panel' },
    features: { icon: 'fas fa-toggle-on', label: 'Özellikler' },
    theme: { icon: 'fas fa-palette', label: 'Tema' },
    notifications: { icon: 'fas fa-bell', label: 'Bildirimler' },
    gold: { icon: 'fas fa-coins', label: 'Altın Yönetimi' },
    goldCalculator: { icon: 'fas fa-calculator', label: 'Altın Hesaplama' }
};

// Default theme configuration
export const defaultTheme = {
    theme_type: 'dark',
    primary_color: '#18214F',
    secondary_color: '#D4B896',
    accent_color: '#FF6B6B',
    background_color: '#FFFFFF',
    text_color: '#000000',
    success_color: '#4CAF50',
    error_color: '#F44336',
    warning_color: '#FF9800',
    font_family: 'Inter',
    font_size_scale: 1.0
};

// API base URL
export const API_BASE_URL = '';  // Empty string for relative URLs

// WebSocket configuration
export const SOCKET_URL = 'http://localhost:3009';

// Notification types
export const NOTIFICATION_TYPES = {
    DATA_ONLY: 'data_only',
    WITH_NOTIFICATION: 'with_notification'
};

// Notification audiences
export const NOTIFICATION_AUDIENCES = {
    AUTHENTICATED: 'authenticated',
    GUEST: 'guest',
    ALL: 'all'
};