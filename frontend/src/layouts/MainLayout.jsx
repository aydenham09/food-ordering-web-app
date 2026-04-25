import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useCart } from '../contexts/CartContext';
import { useState } from 'react';
import { FiShoppingCart, FiMenu, FiX, FiUser, FiLogOut, FiHome, FiGrid, FiClock } from 'react-icons/fi';

export default function MainLayout() {
  const { user, logout } = useAuth();
  const { totalItems } = useCart();
  const [menuOpen, setMenuOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  const isLanding = location.pathname === '/' && !user;

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <div className="app-layout">
      <nav className={`navbar ${isLanding ? 'navbar--landing' : ''}`}>
        <div className="nav-container">
          <Link to="/" className="nav-brand">
            <span className="brand-icon">✦</span>
            <span className="brand-text">GourmetHub</span>
          </Link>

          {user && (
            <div className={`nav-links ${menuOpen ? 'active' : ''}`}>
              <Link to="/" onClick={() => setMenuOpen(false)}><FiHome /> Home</Link>
              <Link to="/menu" onClick={() => setMenuOpen(false)}><FiGrid /> Menu</Link>
              <Link to="/orders" onClick={() => setMenuOpen(false)}><FiClock /> My Orders</Link>
              {user?.role === 'admin' && <Link to="/admin" onClick={() => setMenuOpen(false)}>Admin</Link>}
            </div>
          )}

          <div className="nav-actions">
            {user && (
              <Link to="/cart" className="cart-btn">
                <FiShoppingCart />
                {totalItems > 0 && <span className="cart-badge">{totalItems}</span>}
              </Link>
            )}

            {user ? (
              <div className="user-menu">
                <button className="user-btn"><FiUser /> {user.name}</button>
                <div className="user-dropdown">
                  <Link to="/orders">My Orders</Link>
                  <button onClick={handleLogout}><FiLogOut /> Logout</button>
                </div>
              </div>
            ) : (
              <div className="nav-auth-actions">
                <Link to="/login" className="login-btn-outline">Sign In</Link>
                <Link to="/register" className="login-btn">Get Started</Link>
              </div>
            )}

            {user && (
              <button className="mobile-toggle" onClick={() => setMenuOpen(!menuOpen)}>
                {menuOpen ? <FiX /> : <FiMenu />}
              </button>
            )}
          </div>
        </div>
      </nav>

      <main className="main-content">
        <Outlet />
      </main>

      <footer className="footer">
        <div className="footer-container">
          <div className="footer-brand">
            <span className="brand-icon">✦</span>
            <span>GourmetHub</span>
          </div>
          <p>&copy; 2026 GourmetHub. Crafted with passion for fine dining.</p>
        </div>
      </footer>
    </div>
  );
}
