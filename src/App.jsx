import React, { useState } from 'react';
import './index.css';

const Sidebar = ({ activeTab, setActiveTab }) => {
  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'subscriptions', label: 'Subscriptions', icon: '📱' },
    { id: 'appliances', label: 'Appliances', icon: '🏠' },
    { id: 'vehicles', label: 'Vehicles', icon: '🚗' },
    { id: 'services', label: 'Services', icon: '🛠️' },
  ];

  return (
    <aside className="sidebar glass">
      <div className="logo">
        <span className="text-gradient">HomeSphere</span>
      </div>
      <nav className="nav-list">
        {tabs.map(tab => (
          <button
            key={tab.id}
            className={`nav-item ${activeTab === tab.id ? 'active' : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            <span className="icon">{tab.icon}</span>
            <span className="label">{tab.label}</span>
          </button>
        ))}
      </nav>
      <div className="sidebar-footer">
        <div className="user-profile">
          <div className="avatar">PN</div>
          <div className="user-info">
            <p className="name">Prajwal N</p>
            <p className="status">Pro Account</p>
          </div>
        </div>
      </div>
    </aside>
  );
};

const Header = ({ title }) => (
  <header className="header glass">
    <h2>{title}</h2>
    <div className="header-actions">
      <button className="search-btn">🔍</button>
      <button className="notif-btn">🔔</button>
      <button className="add-btn premium-gradient">Add New +</button>
    </div>
  </header>
);

const Dashboard = () => {
  const stats = [
    { label: 'Active Subscriptions', value: '12', color: '#58a6ff' },
    { label: 'Next Renewal', value: '2 Days', color: '#bc8cf2' },
    { label: 'Vehicles', value: '2', color: '#3fb950' },
    { label: 'Monthly Spend', value: '₹4,200', color: '#ff7b72' },
  ];

  return (
    <div className="dashboard-content animate-fade-in">
      <div className="stats-grid">
        {stats.map(stat => (
          <div key={stat.label} className="stat-card glass">
            <p className="stat-label">{stat.label}</p>
            <p className="stat-value" style={{ color: stat.color }}>{stat.value}</p>
          </div>
        ))}
      </div>
      <div className="content-grid">
        <div className="recent-activity glass">
          <h3>Recent Activity</h3>
          <div className="activity-list">
            {[
              { title: 'Netflix Renewal', time: '2 hours ago', color: '#bc8cf2' },
              { title: 'Car Service Completed', time: 'Yesterday', color: '#3fb950' },
              { title: 'Internet Bill Paid', time: '2 days ago', color: '#58a6ff' },
            ].map((activity, i) => (
              <div key={i} className="activity-item">
                <span className="dot" style={{ background: activity.color }}></span>
                <div>
                  <p className="activity-title">{activity.title}</p>
                  <p className="activity-time">{activity.time}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
        <div className="upcoming-tasks glass">
          <h3>Notifications</h3>
          <div className="activity-list">
            <div className="activity-item">
              <span className="dot" style={{ background: '#ff7b72' }}></span>
              <div>
                <p className="activity-title" style={{ color: '#ff7b72' }}>Insurance Expiring</p>
                <p className="activity-time">Yamaha R15 - 5 days left</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const Subscriptions = () => {
  const subs = [
    { name: 'Netflix', price: '₹649/mo', date: 'Feb 15, 2026', type: 'Entertainment' },
    { name: 'Spotify Premium', price: '₹119/mo', date: 'Feb 20, 2026', type: 'Music' },
    { name: 'ACT Fibernet', price: '₹1,149/mo', date: 'Feb 28, 2026', type: 'Utility' },
  ];
  return (
    <div className="module-view animate-fade-in">
      <div className="module-grid">
        {subs.map(sub => (
          <div key={sub.name} className="data-card glass">
            <div className="data-card-header">
              <h3>{sub.name}</h3>
              <span className="badge badge-active">Active</span>
            </div>
            <p className="stat-label">Next Billing: {sub.date}</p>
            <div className="data-card-footer">
              <p className="stat-value">{sub.price}</p>
              <span className="badge">{sub.type}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

const Appliances = () => {
  const items = [
    { name: 'Samsung Refrigerator', status: 'Healthy', warranty: 'Exp: Dec 2027' },
    { name: 'LG Split AC', status: 'Service Due', warranty: 'Exp: May 2026' },
  ];
  return (
    <div className="module-view animate-fade-in">
      <div className="module-grid">
        {items.map(item => (
          <div key={item.name} className="data-card glass">
            <div className="data-card-header">
              <h3>{item.name}</h3>
              <span className={`badge ${item.status === 'Healthy' ? 'badge-active' : 'badge-warning'}`}>
                {item.status}
              </span>
            </div>
            <p className="stat-label">Warranty: {item.warranty}</p>
            <button className="add-btn premium-gradient" style={{ width: '100%', marginTop: '1rem' }}>Book Service</button>
          </div>
        ))}
      </div>
    </div>
  );
};

const Vehicles = () => {
  const vehicles = [
    { name: 'BMW 3 Series', number: 'KA 01 MG 1234', mileage: '12,500 km', nextService: '15,000 km' },
    { name: 'Yamaha R15 V4', number: 'KA 05 KL 9876', mileage: '4,200 km', nextService: 'Mar 2026' },
  ];
  return (
    <div className="module-view animate-fade-in">
      <div className="module-grid">
        {vehicles.map(v => (
          <div key={v.name} className="data-card glass">
            <div className="data-card-header">
              <h3>{v.name}</h3>
              <span className="badge badge-active">Good</span>
            </div>
            <p className="stat-label">Reg: {v.number}</p>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem' }}>
              <span>Mileage: {v.mileage}</span>
              <span style={{ color: '#58a6ff' }}>Next: {v.nextService}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');

  const getTitle = () => {
    return activeTab.charAt(0).toUpperCase() + activeTab.slice(1);
  };

  return (
    <div className="app-container">
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />
      <div className="main-viewport">
        <Header title={getTitle()} />
        <main className="content-area">
          {activeTab === 'dashboard' && <Dashboard />}
          {activeTab === 'subscriptions' && <Subscriptions />}
          {activeTab === 'appliances' && <Appliances />}
          {activeTab === 'vehicles' && <Vehicles />}
          {activeTab === 'services' && (
            <div className="placeholder-view glass animate-fade-in">
              <h3>Marketplace Coming Soon</h3>
              <p>Connect with electricians, plumbers, and mechanics directly.</p>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
