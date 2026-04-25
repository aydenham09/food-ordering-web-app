import { useCart } from '../contexts/CartContext';
import { Link } from 'react-router-dom';
import { FiMinus, FiPlus, FiTrash2, FiShoppingBag } from 'react-icons/fi';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
export default function Cart() {
  const { items, updateQuantity, removeItem, totalPrice, totalItems } = useCart();

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);

  if (items.length === 0) {
    return (
      <div className="cart-page">
        <div className="empty-state">
          <span className="empty-icon">🛒</span>
          <h3>Your cart is empty</h3>
          <p>Browse our menu and add some delicious items!</p>
          <Link to="/menu" className="btn-primary">Browse Menu</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="cart-page">
      <h1>Shopping Cart <span className="cart-count">({totalItems} items)</span></h1>

      <div className="cart-layout">
        <div className="cart-items">
          {items.map(item => (
            <div key={item.product_id} className="cart-item">
              <div className="cart-item-image">
                {item.product.image ? (
                  <img src={item.product.image.startsWith('/') ? item.product.image : `${API_URL}/storage/${item.product.image}`} alt={item.product.name} />
                ) : (
                  <div className="item-placeholder">🍽️</div>
                )}
              </div>

              <div className="cart-item-info">
                <h3>{item.product.name}</h3>
                <span className="item-price">{formatPrice(item.product.price)}</span>
              </div>

              <div className="cart-item-actions">
                <div className="qty-control">
                  <button onClick={() => updateQuantity(item.product_id, item.quantity - 1)}><FiMinus /></button>
                  <span>{item.quantity}</span>
                  <button onClick={() => updateQuantity(item.product_id, item.quantity + 1)}><FiPlus /></button>
                </div>
                <span className="item-subtotal">{formatPrice(item.product.price * item.quantity)}</span>
                <button className="remove-btn" onClick={() => removeItem(item.product_id)}><FiTrash2 /></button>
              </div>
            </div>
          ))}
        </div>

        <div className="cart-summary">
          <h3>Order Summary</h3>
          <div className="summary-row">
            <span>Subtotal ({totalItems} items)</span>
            <span>{formatPrice(totalPrice)}</span>
          </div>
          <div className="summary-row total">
            <span>Total</span>
            <span>{formatPrice(totalPrice)}</span>
          </div>
          <Link to="/checkout" className="btn-primary checkout-btn">
            <FiShoppingBag /> Proceed to Checkout
          </Link>
        </div>
      </div>
    </div>
  );
}
