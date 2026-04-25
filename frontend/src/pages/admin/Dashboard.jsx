import { useState, useEffect } from 'react';
import { adminApi } from '../../api';
import { FiDollarSign, FiShoppingBag, FiUsers, FiGrid } from 'react-icons/fi';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

const COLORS = ['#ff6b35', '#f7c948', '#22c55e', '#3b82f6', '#ef4444'];

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null); // ✅ tambah state error

  useEffect(() => {
    adminApi.getDashboard()
      .then(res => setData(res.data))
      .catch(err => {
        console.error('Dashboard fetch error:', err);
        setError(err.response?.data?.message || 'Gagal memuat data dashboard.');
      })
      .finally(() => setLoading(false));
  }, []);

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price ?? 0);

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  // ✅ tampilkan pesan error kalau fetch gagal (bukan blank)
  if (error || !data) return (
    <div className="admin-dashboard">
      <h1>Dashboard</h1>
      <div style={{ color: '#ef4444', marginTop: '2rem' }}>
        ⚠️ {error ?? 'Data tidak ditemukan.'}
      </div>
    </div>
  );

  return (
    <div className="admin-dashboard">
      <h1>Dashboard</h1>

      <div className="stats-grid">
        <div className="stat-card orange">
          <div className="stat-icon"><FiDollarSign /></div>
          <div className="stat-info">
            <span className="stat-value">{formatPrice(data.total_revenue)}</span>
            <span className="stat-label">Total Revenue</span>
          </div>
        </div>
        <div className="stat-card blue">
          <div className="stat-icon"><FiShoppingBag /></div>
          <div className="stat-info">
            <span className="stat-value">{data.total_orders ?? 0}</span>
            <span className="stat-label">Total Orders</span>
          </div>
        </div>
        <div className="stat-card green">
          <div className="stat-icon"><FiGrid /></div>
          <div className="stat-info">
            <span className="stat-value">{data.total_products ?? 0}</span>
            <span className="stat-label">Products</span>
          </div>
        </div>
        <div className="stat-card purple">
          <div className="stat-icon"><FiUsers /></div>
          <div className="stat-info">
            <span className="stat-value">{data.total_customers ?? 0}</span>
            <span className="stat-label">Customers</span>
          </div>
        </div>
      </div>

      <div className="charts-grid">
        <div className="chart-card">
          <h3>Orders by Status</h3>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart>
              {/* ✅ fallback ke array kosong kalau null/undefined */}
              <Pie data={data.orders_by_status ?? []} dataKey="count" nameKey="status" cx="50%" cy="50%" outerRadius={80} label={({ status, count }) => `${status}: ${count}`}>
                {(data.orders_by_status ?? []).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="chart-card">
          <h3>Popular Products</h3>
          <ResponsiveContainer width="100%" height={250}>
            {/* ✅ fallback ke array kosong kalau null/undefined */}
            <BarChart data={data.popular_products ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
              <XAxis dataKey="name" tick={{ fill: '#94a3b8', fontSize: 12 }} angle={-20} textAnchor="end" height={60} />
              <YAxis tick={{ fill: '#94a3b8' }} />
              <Tooltip contentStyle={{ background: '#1e293b', border: 'none', borderRadius: 8, color: '#e2e8f0' }} />
              <Bar dataKey="order_count" fill="#ff6b35" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="recent-orders-card">
        <h3>Recent Orders</h3>
        <table className="admin-table">
          <thead>
            <tr><th>Order</th><th>Customer</th><th>Amount</th><th>Status</th><th>Payment</th></tr>
          </thead>
          <tbody>
            {/* ✅ fallback ke array kosong kalau null/undefined */}
            {(data.recent_orders ?? []).map(order => (
              <tr key={order.id}>
                <td>{order.order_number}</td>
                <td>{order.user?.name}</td>
                <td>{formatPrice(order.total_amount)}</td>
                <td><span className={`status-badge status-${order.status}`}>{order.status}</span></td>
                <td>{order.payment?.method?.toUpperCase()} — {order.payment?.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}