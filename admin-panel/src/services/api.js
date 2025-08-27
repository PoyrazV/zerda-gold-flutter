import { API_BASE_URL } from '../utils/constants';

// Helper function to get auth headers
const getAuthHeaders = () => {
    const token = localStorage.getItem('admin_token');
    return {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
    };
};

// Authentication API
export const authAPI = {
    login: async (username, password) => {
        const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        return response.json();
    },
    
    logout: () => {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
    }
};

// Customers API
export const customersAPI = {
    getAll: async () => {
        const response = await fetch(`${API_BASE_URL}/api/customers`, {
            headers: getAuthHeaders()
        });
        return response.json();
    }
};

// Features API
export const featuresAPI = {
    getByCustomer: async (customerId) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/features`);
        return response.json();
    },
    
    toggleFeature: async (customerId, featureName, enabled) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/features/${featureName}`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ enabled })
        });
        return response.json();
    }
};

// Theme API
export const themeAPI = {
    getByCustomer: async (customerId) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/theme`);
        return response.json();
    },
    
    updateTheme: async (customerId, themeConfig) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/theme`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(themeConfig)
        });
        return response.json();
    },
    
    uploadAsset: async (customerId, assetType, file) => {
        const formData = new FormData();
        formData.append('file', file);
        
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/assets/${assetType}`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
            },
            body: formData
        });
        return response.json();
    }
};

// Dashboard Stats API
export const statsAPI = {
    getDashboardStats: async () => {
        const response = await fetch(`${API_BASE_URL}/api/dashboard/stats`, {
            headers: getAuthHeaders()
        });
        return response.json();
    }
};

// Notifications API
export const notificationsAPI = {
    getNotifications: async (customerId) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/notifications`, {
            headers: getAuthHeaders()
        });
        return response.json();
    },
    
    getNotificationStats: async (customerId) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/notifications/stats`, {
            headers: getAuthHeaders()
        });
        return response.json();
    },
    
    sendNotification: async (customerId, notification) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/notifications/send`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(notification)
        });
        return response.json();
    },
    
    deleteNotification: async (customerId, notificationId) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/notifications/${notificationId}`, {
            method: 'DELETE',
            headers: getAuthHeaders()
        });
        return response.json();
    }
};

// Gold Management API
export const goldAPI = {
    getProducts: async (customerId) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/gold-products`);
        return response.json();
    },
    
    getGoldPrice: async () => {
        const response = await fetch(`${API_BASE_URL}/api/gold/price`);
        return response.json();
    },
    
    addProduct: async (customerId, product) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/gold-products`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(product)
        });
        return response.json();
    },
    
    updateProduct: async (customerId, productId, product) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/gold-products/${productId}`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify(product)
        });
        return response.json();
    },
    
    deleteProduct: async (customerId, productId) => {
        const response = await fetch(`${API_BASE_URL}/api/customers/${customerId}/gold-products/${productId}`, {
            method: 'DELETE',
            headers: getAuthHeaders()
        });
        return response.json();
    }
};