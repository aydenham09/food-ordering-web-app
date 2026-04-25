import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { FiHome, FiGrid, FiShoppingBag, FiUsers, FiBarChart2, FiTag, FiLogOut, FiMenu, FiX, FiPieChart } from 'react-icons/fi';
import { useState } from 'react';

const menuItems = [
  { path: '/admin', icon: <FiPieChart />, label: 'Dashboard', exact: true },
  { path: '/admin/products', icon: <FiGrid />, label: 'Products' },
  { path: '/admin/categories', icon: <FiTag />, label: 'Categories' },
  { path: '/admin/orders', icon: <FiShoppingBag />, label: 'Orders' },
  { path: '/admin/users', icon: <FiUsers />, label: 'Users' },
  { path: '/admin/reports', icon: <FiBarChart2 />, label: 'Reports' },
];

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <div className="admin-layout">
      <aside className={`admin-sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="sidebar-header">
          <Link to="/" className="sidebar-brand">
            <span>✦</span> GourmetHub
          </Link>
          <button className="sidebar-close" onClick={() => setSidebarOpen(false)}><FiX /></button>
        </div>

        <nav className="sidebar-nav">
          {menuItems.map(item => (
            <Link
              key={item.path}
              to={item.path}
              className={`sidebar-link ${
                item.exact
                  ? location.pathname === item.path ? 'active' : ''
                  : location.pathname.startsWith(item.path) ? 'active' : ''
              }`}
              onClick={() => setSidebarOpen(false)}
            >
              {item.icon} {item.label}
            </Link>
          ))}
        </nav>

        <div className="sidebar-footer">
          <Link to="/" className="sidebar-link"><FiHome /> Back to Store</Link>
          <button onClick={handleLogout} className="sidebar-link logout-btn">
            <FiLogOut /> Logout
          </button>
        </div>
      </aside>

      <div className="admin-main">
        <header className="admin-header">
          <button className="admin-menu-toggle" onClick={() => setSidebarOpen(true)}>
            <FiMenu />
          </button>
          <h2 className="admin-title">Admin Panel</h2>
          <div className="admin-user">
            <FiUsers /> {user?.name}
          </div>
        </header>
        <div className="admin-content">
          <Outlet />
        </div>
      </div>

      {sidebarOpen && <div className="sidebar-overlay" onClick={() => setSidebarOpen(false)} />}
    </div>
  );
}
