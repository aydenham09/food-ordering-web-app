import { useCart } from '../contexts/CartContext';
import { FiPlus, FiStar } from 'react-icons/fi';
import { Link } from 'react-router-dom';
import toast from 'react-hot-toast';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export default function ProductCard({ product }) {
  const { addItem } = useCart();

  const handleAdd = (e) => {
    e.preventDefault();
    e.stopPropagation();
    addItem(product);
    toast.success(`${product.name} added to cart!`);
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);
  };

  return (
    <Link to={`/products/${product.id}`} className="product-card">
      <div className="product-image">
        {product.image ? (
          <img src={product.image.startsWith('/') ? product.image : `${API_URL}/storage/${product.image}`} alt={product.name} />
        ) : (
          <div className="product-placeholder">🍽️</div>
        )}
        {product.order_count > 50 && <span className="badge-bestseller">🔥 Best Seller</span>}
      </div>

      <div className="product-info">
        <span className="product-category">{product.category?.name}</span>
        <h3 className="product-name">{product.name}</h3>
        <p className="product-desc">{product.description?.substring(0, 60)}...</p>

        <div className="product-meta">
          <div className="product-rating">
            <FiStar className="star-icon" />
            <span>{Number(product.avg_rating).toFixed(1)}</span>
          </div>
          <span className="product-orders">{product.order_count} orders</span>
        </div>

        <div className="product-footer">
          <span className="product-price">{formatPrice(product.price)}</span>
          <button className="add-btn" onClick={handleAdd} title="Add to cart">
            <FiPlus />
          </button>
        </div>
      </div>
    </Link>
  );
}
