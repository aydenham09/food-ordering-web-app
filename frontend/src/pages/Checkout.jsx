import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../contexts/CartContext';
import { useAuth } from '../contexts/AuthContext';
import { orderApi } from '../api';
import { QRCodeSVG } from 'qrcode.react';
import toast from 'react-hot-toast';
import { FiCreditCard, FiDollarSign } from 'react-icons/fi';

export default function Checkout() {
  const { items, totalPrice, clearCart } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [paymentMethod, setPaymentMethod] = useState('cash');
  const [notes, setNotes] = useState('');
  const [orderType, setOrderType] = useState('take_away');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [tableNumber, setTableNumber] = useState('');
  const [deliveryPhoto, setDeliveryPhoto] = useState(null);
  const [loading, setLoading] = useState(false);
  const [order, setOrder] = useState(null);

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);

  if (!user) {
    navigate('/login');
    return null;
  }

  if (items.length === 0 && !order) {
    navigate('/cart');
    return null;
  }

  const handlePlaceOrder = async () => {
    if (orderType === 'delivery' && !deliveryAddress.trim()) return toast.error('Delivery address is required');
    if (orderType === 'dine_in' && !tableNumber.trim()) return toast.error('Table number is required');

    setLoading(true);
    try {
      const formData = new FormData();
      formData.append('payment_method', paymentMethod);
      formData.append('order_type', orderType);
      if (notes) formData.append('notes', notes);
      
      if (orderType === 'delivery') {
        formData.append('delivery_address', deliveryAddress);
        if (deliveryPhoto) formData.append('delivery_photo', deliveryPhoto);
      } else if (orderType === 'dine_in') {
        formData.append('table_number', tableNumber);
      }

      items.forEach((item, index) => {
        formData.append(`items[${index}][product_id]`, item.product_id);
        formData.append(`items[${index}][quantity]`, item.quantity);
      });

      const res = await orderApi.create(formData);
      setOrder(res.data);
      clearCart();
      toast.success('Order placed successfully!');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to place order');
    } finally {
      setLoading(false);
    }
  };

  if (order) {
    return (
      <div className="checkout-page">
        <div className="order-success">
          <div className="success-icon">✅</div>
          <h2>Order Placed Successfully!</h2>
          <p className="order-number">Order #{order.order_number}</p>

          {order.payment?.method === 'qris' && order.payment?.status === 'pending' && (
            <div className="qris-section">
              <h3>Scan QRIS to Pay</h3>
              <div className="qris-code">
                <QRCodeSVG value={order.payment.qris_code} size={200} />
              </div>
              <p className="qris-amount">{formatPrice(order.payment.amount)}</p>
              <p className="qris-note">Show this QR code to the cashier or scan with your e-wallet</p>
            </div>
          )}

          {order.payment?.method === 'cash' && (
            <div className="cash-section">
              <h3>💵 Pay at Counter</h3>
              <p className="cash-amount">{formatPrice(order.payment.amount)}</p>
              <p>Please pay at the counter when your order is ready.</p>
            </div>
          )}

          <button onClick={() => navigate('/orders')} className="btn-primary">
            View My Orders
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="checkout-page">
      <h1>Checkout</h1>

      <div className="checkout-layout">
        <div className="checkout-form">
          <div className="checkout-section">
            <h3>Order Items</h3>
            {items.map(item => (
              <div key={item.product_id} className="checkout-item">
                <span>{item.product.name} x{item.quantity}</span>
                <span>{formatPrice(item.product.price * item.quantity)}</span>
              </div>
            ))}
          </div>

          <div className="checkout-section">
            <h3>Payment Method</h3>
            <div className="payment-options">
              <label className={`payment-option ${paymentMethod === 'cash' ? 'selected' : ''}`}>
                <input type="radio" value="cash" checked={paymentMethod === 'cash'} onChange={(e) => setPaymentMethod(e.target.value)} />
                <FiDollarSign /> Cash
                <span className="option-desc">Pay at the counter</span>
              </label>
              <label className={`payment-option ${paymentMethod === 'qris' ? 'selected' : ''}`}>
                <input type="radio" value="qris" checked={paymentMethod === 'qris'} onChange={(e) => setPaymentMethod(e.target.value)} />
                <FiCreditCard /> QRIS
                <span className="option-desc">Scan QR code to pay</span>
              </label>
            </div>
          </div>

          <div className="checkout-section">
            <h3>Order Type</h3>
            <div className="payment-options">
              <label className={`payment-option ${orderType === 'take_away' ? 'selected' : ''}`}>
                <input type="radio" value="take_away" checked={orderType === 'take_away'} onChange={(e) => setOrderType(e.target.value)} />
                🛍️ Takeaway
              </label>
              <label className={`payment-option ${orderType === 'dine_in' ? 'selected' : ''}`}>
                <input type="radio" value="dine_in" checked={orderType === 'dine_in'} onChange={(e) => setOrderType(e.target.value)} />
                🪑 Dine-in
              </label>
              <label className={`payment-option ${orderType === 'delivery' ? 'selected' : ''}`}>
                <input type="radio" value="delivery" checked={orderType === 'delivery'} onChange={(e) => setOrderType(e.target.value)} />
                🛵 Delivery
              </label>
            </div>
            
            {orderType === 'dine_in' && (
              <div className="form-group" style={{ marginTop: 16 }}>
                <label>Table Number</label>
                <input type="text" placeholder="e.g. 12 or A3" value={tableNumber} onChange={e => setTableNumber(e.target.value)} />
              </div>
            )}

            {orderType === 'delivery' && (
              <div style={{ marginTop: 16 }}>
                <div className="form-group">
                  <label>Full Address</label>
                  <textarea placeholder="Enter your full delivery address" value={deliveryAddress} onChange={e => setDeliveryAddress(e.target.value)} />
                </div>
                <div className="form-group" style={{ marginTop: 16 }}>
                  <label>Drop-off Photo (Optional)</label>
                  <input type="file" accept="image/*" onChange={e => setDeliveryPhoto(e.target.files[0])} style={{ background: 'var(--bg-tertiary)', padding: 12, borderRadius: 8, width: '100%', marginTop: 8 }} />
                  <span className="image-upload-hint" style={{ display: 'block', marginTop: 4 }}>Upload a photo of where you want the food placed</span>
                </div>
              </div>
            )}
          </div>

          <div className="checkout-section">
            <h3>Notes</h3>
            <textarea placeholder="Any special requests? (e.g., extra spicy, no onions)" value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
        </div>

        <div className="checkout-summary">
          <h3>Order Summary</h3>
          <div className="summary-row">
            <span>Subtotal</span>
            <span>{formatPrice(totalPrice)}</span>
          </div>
          <div className="summary-row total">
            <span>Total</span>
            <span>{formatPrice(totalPrice)}</span>
          </div>
          <button className="btn-primary place-order-btn" onClick={handlePlaceOrder} disabled={loading}>
            {loading ? 'Placing Order...' : 'Place Order'}
          </button>
        </div>
      </div>
    </div>
  );
}
