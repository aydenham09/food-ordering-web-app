import { useState, useEffect } from 'react';
import { adminApi } from '../../api';
import toast from 'react-hot-toast';

export default function Orders() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');

  const fetchOrders = () => {
    const params = {};
    if (filter) params.status = filter;
    adminApi.getOrders(params).then(res => setOrders(res.data.data)).finally(() => setLoading(false));
  };

  useEffect(() => { fetchOrders(); }, [filter]);

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);

  const updateStatus = async (id, status) => {
    try {
      await adminApi.updateOrderStatus(id, { status });
      toast.success(`Order updated to ${status}`);
      fetchOrders();
    } catch { toast.error('Failed to update order'); }
  };

  const statuses = ['pending', 'confirmed', 'preparing', 'completed', 'cancelled'];

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  return (
    <div className="admin-crud-page">
      <div className="crud-header">
        <h1>Orders</h1>
        <div className="filter-group">
          <select value={filter} onChange={e => setFilter(e.target.value)}>
            <option value="">All Status</option>
            {statuses.map(s => <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>)}
          </select>
        </div>
      </div>

      <table className="admin-table">
        <thead>
          <tr><th>Order #</th><th>Customer</th><th>Items</th><th>Total</th><th>Payment</th><th>Status</th><th>Actions</th></tr>
        </thead>
        <tbody>
          {orders.map(order => (
            <tr key={order.id}>
              <td>{order.order_number}</td>
              <td>{order.user?.name}</td>
              <td>{order.items?.length} items</td>
              <td>{formatPrice(order.total_amount)}</td>
              <td>
                <span className="payment-method-badge">{order.payment?.method?.toUpperCase()}</span>
                <span className={`payment-status-badge ${order.payment?.status}`}>{order.payment?.status}</span>
              </td>
              <td><span className={`status-badge status-${order.status}`}>{order.status}</span></td>
              <td>
                <select value={order.status} onChange={e => updateStatus(order.id, e.target.value)} className="status-select">
                  {statuses.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
