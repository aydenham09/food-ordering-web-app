import { useState, useEffect } from 'react';
import { adminApi } from '../../api';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts';

export default function Reports() {
  const [sales, setSales] = useState(null);
  const [popular, setPopular] = useState([]);
  const [days, setDays] = useState(30);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      adminApi.getSalesReport({ days }),
      adminApi.getPopularReport(),
    ]).then(([salesRes, popularRes]) => {
      setSales(salesRes.data);
      setPopular(popularRes.data);
    }).finally(() => setLoading(false));
  }, [days]);

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  return (
    <div className="admin-reports">
      <div className="crud-header">
        <h1>Reports</h1>
        <select value={days} onChange={e => setDays(Number(e.target.value))} className="period-select">
          <option value={7}>Last 7 days</option>
          <option value={30}>Last 30 days</option>
          <option value={90}>Last 90 days</option>
        </select>
      </div>

      <div className="report-stats">
        <div className="stat-card orange">
          <span className="stat-value">{formatPrice(sales?.total_revenue || 0)}</span>
          <span className="stat-label">Total Revenue ({days} days)</span>
        </div>
        <div className="stat-card blue">
          <span className="stat-value">{sales?.total_orders || 0}</span>
          <span className="stat-label">Total Orders ({days} days)</span>
        </div>
      </div>

      <div className="charts-grid">
        <div className="chart-card">
          <h3>Daily Sales</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={sales?.sales || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
              <XAxis dataKey="date" tick={{ fill: '#94a3b8', fontSize: 11 }} />
              <YAxis tick={{ fill: '#94a3b8' }} />
              <Tooltip contentStyle={{ background: '#1e293b', border: 'none', borderRadius: 8, color: '#e2e8f0' }} formatter={(v) => formatPrice(v)} />
              <Line type="monotone" dataKey="total" stroke="#ff6b35" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="chart-card">
          <h3>Most Popular Items</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={popular} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
              <XAxis type="number" tick={{ fill: '#94a3b8' }} />
              <YAxis dataKey="name" type="category" width={120} tick={{ fill: '#94a3b8', fontSize: 12 }} />
              <Tooltip contentStyle={{ background: '#1e293b', border: 'none', borderRadius: 8, color: '#e2e8f0' }} />
              <Bar dataKey="order_count" fill="#f7c948" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
