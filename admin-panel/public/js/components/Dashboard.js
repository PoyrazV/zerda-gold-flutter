// Dashboard Component
const Dashboard = ({ stats, realtimeStatus, selectedCustomer }) => {
    return React.createElement('div', null,
        React.createElement('div', { className: 'stats-grid' },
            React.createElement('div', { className: 'stat-card customers' },
                React.createElement('div', { className: 'stat-icon' },
                    React.createElement('i', { className: 'fas fa-users' })
                ),
                React.createElement('div', { className: 'stat-number' }, stats.totalCustomers || 0),
                React.createElement('div', { className: 'stat-label' }, 'Müşteriler')
            ),
            React.createElement('div', { className: 'stat-card features' },
                React.createElement('div', { className: 'stat-icon' },
                    React.createElement('i', { className: 'fas fa-toggle-on' })
                ),
                React.createElement('div', { className: 'stat-number' }, stats.activeFeatures || 0),
                React.createElement('div', { className: 'stat-label' }, 'Aktif Özellikler')
            ),
            React.createElement('div', { className: 'stat-card assets' },
                React.createElement('div', { className: 'stat-icon' },
                    React.createElement('i', { className: 'fas fa-coins' })
                ),
                React.createElement('div', { className: 'stat-number' }, stats.totalGoldAssets || 0),
                React.createElement('div', { className: 'stat-label' }, 'Eklenen Altın Varlıkları')
            ),
            React.createElement('div', { className: 'stat-card builds' },
                React.createElement('div', { className: 'stat-icon' },
                    React.createElement('i', { className: 'fas fa-user-check' })
                ),
                React.createElement('div', { className: 'stat-number' }, stats.totalUsers || 0),
                React.createElement('div', { className: 'stat-label' }, 'Kullanıcı Sayısı')
            )
        ),
        React.createElement('div', { className: 'section-card' },
            React.createElement('div', { className: 'section-header' },
                React.createElement('h2', { className: 'section-title' },
                    React.createElement('i', { className: 'fas fa-chart-line' }),
                    ' Sistem Durumu'
                )
            ),
            React.createElement('div', { className: 'section-content' },
                React.createElement('p', null, '📊 Sistem sağlıklı çalışıyor'),
                React.createElement('p', null,
                    '🔌 WebSocket Bağlantısı: ',
                    React.createElement('strong', null, realtimeStatus === 'connected' ? 'Aktif' : 'Pasif')
                ),
                React.createElement('p', null,
                    '👥 Seçili Müşteri: ',
                    React.createElement('strong', null, selectedCustomer?.display_name || 'Seçilmedi')
                ),
                React.createElement('p', null,
                    '⚡ Son Güncelleme: ',
                    React.createElement('strong', null, new Date().toLocaleString('tr-TR'))
                )
            )
        )
    );
};

window.Dashboard = Dashboard;