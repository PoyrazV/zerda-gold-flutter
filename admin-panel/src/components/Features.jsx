import React from 'react';
import { featureOrder, featureDisplayNames, featureDescriptions } from '../utils/constants';

const Features = ({ features, selectedCustomer, toggleFeature }) => {
    return (
        <div className="section-card">
            <div className="section-header">
                <h2 className="section-title"><i className="fas fa-toggle-on"></i> Özellik Yönetimi</h2>
                <div style={{ color: '#D4B896', fontSize: '14px' }}>
                    Müşteri: {selectedCustomer?.display_name}
                </div>
            </div>
            <div className="section-content">
                <div className="feature-grid">
                    {featureOrder.map((name) => {
                        const enabled = features[name];
                        if (enabled === undefined) return null;
                        return (
                            <div key={name} className={`feature-card ${enabled ? 'enabled' : 'disabled'}`}>
                                <div className="feature-header">
                                    <div>
                                        <div className="feature-name">{featureDisplayNames[name] || name}</div>
                                        <div className="feature-description">
                                            {featureDescriptions[name] || 'Özellik açıklaması'}
                                        </div>
                                    </div>
                                    <div 
                                        className={`toggle-switch ${enabled ? 'active' : ''}`}
                                        onClick={() => toggleFeature(name, !enabled)}
                                    >
                                        <div className="toggle-slider"></div>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            </div>
        </div>
    );
};

export default Features;