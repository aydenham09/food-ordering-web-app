import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { orderApi, paymentApi } from '../api';
import { QRCodeSVG } from 'qrcode.react';
import toast from 'react-hot-toast';

export default function OrderHistory() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchOrders = () => {
    orderApi.getAll().then(res => setOrders(res.data.data)).finally(() => setLoading(false));
  };

  useEffect(() => { fetchOrders(); }, []);

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);

  const statusColors = {
    pending: 'status-pending',
    confirmed: 'status-confirmed',
    preparing: 'status-preparing',
    completed: 'status-completed',
    cancelled: 'status-cancelled',
  };

  const handleSimulateQris = async (orderId) => {
    try {
      await paymentApi.simulateQris(orderId);
      toast.success('QRIS payment confirmed!');
      fetchOrders();
    } catch {
      toast.error('Failed to simulate payment');
    }
  };

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  return (
    <div className="orders-page">
      <h1>My Orders</h1>

      {orders.length === 0 ? (
        <div className="empty-state">
          <span className="empty-icon">📦</span>
          <h3>No orders yet</h3>
          <p>Place your first order now!</p>
          <Link to="/menu" className="btn-primary">Browse Menu</Link>
        </div>
      ) : (
        <div className="orders-list">
          {orders.map(order => (
            <div key={order.id} className="order-card">
              <div className="order-header">
                <div>
                  <h3 className="order-number">{order.order_number}</h3>
                  <span className="order-date">{new Date(order.created_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}</span>
                </div>
                <span className={`status-badge ${statusColors[order.status]}`}>{order.status}</span>
              </div>

              <div className="order-items-list">
                {order.items?.map(item => (
                  <div key={item.id} className="order-item-row">
                    <span>{item.product?.name} x{item.quantity}</span>
                    <span>{formatPrice(item.subtotal)}</span>
                  </div>
                ))}
              </div>

              <div className="order-footer">
                <div className="order-payment">
                  <span className="payment-method">{order.payment?.method?.toUpperCase()}</span>
                  <span className={`payment-status ${order.payment?.status === 'paid' ? 'paid' : 'unpaid'}`}>
                    {order.payment?.status}
                  </span>
                </div>
                <span className="order-total">{formatPrice(order.total_amount)}</span>
              </div>

              {order.payment?.method === 'qris' && order.payment?.status === 'pending' && (
                <div className="qris-pay-section">
                  <QRCodeSVG value={order.payment.qris_code} size={120} />
                  <button className="btn-secondary" onClick={() => handleSimulateQris(order.id)}>
                    Simulate QRIS Payment
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
