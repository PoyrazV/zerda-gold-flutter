import React from 'react';

const Dashboard = ({ stats, realtimeStatus, selectedCustomer }) => {
    return (
        <div>
            <div className="stats-grid">
                <div className="stat-card customers">
                    <div className="stat-icon"><i className="fas fa-users"></i></div>
                    <div className="stat-number">{stats.totalCustomers || 0}</div>
                    <div className="stat-label">Müşteriler</div>
                </div>
                
                <div className="stat-card features">
                    <div className="stat-icon"><i className="fas fa-toggle-on"></i></div>
                    <div className="stat-number">{stats.activeFeatures || 0}</div>
                    <div className="stat-label">Aktif Özellikler</div>
                </div>
                
                <div className="stat-card assets">
                    <div className="stat-icon"><i className="fas fa-coins"></i></div>
                    <div className="stat-number">{stats.totalGoldAssets || 0}</div>
                    <div className="stat-label">Eklenen Altın Varlıkları</div>
                </div>
                
                <div className="stat-card builds">
                    <div className="stat-icon"><i className="fas fa-user-check"></i></div>
                    <div className="stat-number">{stats.totalUsers || 0}</div>
                    <div className="stat-label">Kullanıcı Sayısı</div>
                </div>
            </div>

            <div className="section-card">
                <div className="section-header">
                    <h2 className="section-title"><i className="fas fa-chart-line"></i> Sistem Durumu</h2>
                </div>
                <div className="section-content">
                    <p>📊 Sistem sağlıklı çalışıyor</p>
                    <p>🔌 WebSocket Bağlantısı: <strong>{realtimeStatus === 'connected' ? 'Aktif' : 'Pasif'}</strong></p>
                    <p>👥 Seçili Müşteri: <strong>{selectedCustomer?.display_name || 'Seçilmedi'}</strong></p>
                    <p>⚡ Son Güncelleme: <strong>{new Date().toLocaleString('tr-TR')}</strong></p>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;