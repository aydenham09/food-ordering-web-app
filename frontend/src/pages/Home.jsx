import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { productApi, categoryApi } from '../api';
import { useAuth } from '../contexts/AuthContext';
import ProductCard from '../components/ProductCard';
import { FiSearch, FiArrowRight, FiCheck, FiClock, FiStar, FiShield } from 'react-icons/fi';

export default function Home() {
  const { user } = useAuth();
  const [recommended, setRecommended] = useState([]);
  const [categories, setCategories] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    Promise.all([
      productApi.getRecommended(),
      categoryApi.getAll(),
    ]).then(([recRes, catRes]) => {
      setRecommended(recRes.data);
      setCategories(catRes.data);
    }).finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    if (!loading) {
      requestAnimationFrame(() => setMounted(true));
    }
  }, [loading]);

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  return (
    <div className={`home-page ${mounted ? 'home-mounted' : ''}`}>
      {/* ── HERO ── */}
      <section className="hero hero--centered">
        <div className="hero-content">
          <p className="hero-tagline enter enter-d1">Premium Food Ordering</p>
          <h1 className="hero-title enter enter-d2">
            Exquisite Flavors,<br />
            <span className="highlight">Delivered Fresh</span>
          </h1>
          <p className="hero-subtitle enter enter-d3">
            Discover our curated menu of artisan dishes, crafted with the finest ingredients and delivered straight to your table.
          </p>
          <div className="hero-search enter enter-d4">
            <FiSearch />
            <input
              type="text"
              placeholder="Search our curated menu..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && search && (window.location.href = `/menu?search=${search}`)}
            />
          </div>
          <div className="hero-stats enter enter-d5">
            <div className="stat"><span className="stat-num">17+</span><span>Menu Items</span></div>
            <div className="stat-divider"></div>
            <div className="stat"><span className="stat-num">500+</span><span>Orders Served</span></div>
            <div className="stat-divider"></div>
            <div className="stat"><span className="stat-num">4.7</span><span>Avg Rating</span></div>
          </div>
        </div>
      </section>

      {/* ── FEATURES ── */}
      <section className="features-section">
        <div className="features-grid">
          <div className="feature-card enter enter-d3">
            <div className="feature-icon"><FiClock /></div>
            <h3>Fast Delivery</h3>
            <p>Fresh food delivered in under 30 minutes, straight from our kitchen.</p>
          </div>
          <div className="feature-card enter enter-d4">
            <div className="feature-icon"><FiStar /></div>
            <h3>Top Quality</h3>
            <p>Premium ingredients sourced from trusted local partners.</p>
          </div>
          <div className="feature-card enter enter-d5">
            <div className="feature-icon"><FiShield /></div>
            <h3>Secure Payment</h3>
            <p>Pay safely with Cash or QRIS — your choice, your comfort.</p>
          </div>
          <div className="feature-card enter enter-d6">
            <div className="feature-icon"><FiCheck /></div>
            <h3>Easy Ordering</h3>
            <p>Browse, select, and checkout in just a few taps.</p>
          </div>
        </div>
      </section>

      {/* ── CATEGORIES ── */}
      <section className="categories-section">
        <div className="section-header enter enter-d2">
          <h2>Browse Categories</h2>
          <Link to="/menu" className="see-all">See All <FiArrowRight /></Link>
        </div>
        <div className="category-grid">
          {categories.map((cat, i) => (
            <Link
              to={`/menu?category=${cat.id}`}
              key={cat.id}
              className={`category-card enter enter-d${Math.min(i + 3, 8)}`}
            >
              <span className="category-name">{cat.name}</span>
              <span className="category-count">{cat.products_count} items</span>
            </Link>
          ))}
        </div>
      </section>

      {/* ── CHEF'S SELECTION ── */}
      <section className="recommended-section">
        <div className="section-header enter enter-d2">
          <h2>Chef's Selection</h2>
          <Link to="/menu" className="see-all">View Full Menu <FiArrowRight /></Link>
        </div>
        <div className="product-grid">
          {recommended.slice(0, 8).map((product, i) => (
            <div key={product.id} className={`enter enter-d${Math.min(i + 3, 8)}`}>
              <ProductCard product={product} />
            </div>
          ))}
        </div>
      </section>

      {/* ── CTA ── */}
      {!user && (
        <section className="cta-section">
          <div className="cta-content enter enter-d2">
            <h2>Ready to Order?</h2>
            <p>Create an account and start exploring our exquisite menu today.</p>
            <div className="cta-actions">
              <Link to="/register" className="btn-primary">Get Started</Link>
              <Link to="/menu" className="btn-secondary">Browse Menu</Link>
            </div>
          </div>
        </section>
      )}
    </div>
  );
}
