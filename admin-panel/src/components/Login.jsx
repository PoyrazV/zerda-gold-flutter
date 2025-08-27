import React, { useState } from 'react';
import { authAPI } from '../services/api';

const Login = ({ onLogin, showNotification, setLoading }) => {
    const [username, setUsername] = useState('admin');
    const [password, setPassword] = useState('admin123');
    const [localLoading, setLocalLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLocalLoading(true);
        setLoading(true);
        
        try {
            const data = await authAPI.login(username, password);
            
            if (data.success) {
                localStorage.setItem('admin_token', data.data.token);
                localStorage.setItem('admin_user', JSON.stringify(data.data.user));
                onLogin(data.data.user);
                showNotification('Başarıyla giriş yapıldı!', 'success');
            } else {
                showNotification(data.error || 'Giriş başarısız', 'error');
            }
        } catch (error) {
            showNotification('Bağlantı hatası', 'error');
        } finally {
            setLocalLoading(false);
            setLoading(false);
        }
    };

    return (
        <div className="login-container">
            <div className="login-card">
                <h1><i className="fas fa-shield-alt"></i> Zerda Admin</h1>
                <p>Gelişmiş Yönetim Paneli v2.0</p>
                
                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label>Kullanıcı Adı</label>
                        <input
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            required
                        />
                    </div>
                    
                    <div className="form-group">
                        <label>Şifre</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>
                    
                    <button type="submit" className="login-btn" disabled={localLoading}>
                        {localLoading ? 'Giriş yapılıyor...' : 'Giriş Yap'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default Login;