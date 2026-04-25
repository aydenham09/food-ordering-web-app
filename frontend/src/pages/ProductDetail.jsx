import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { productApi, reviewApi } from '../api';
import { useCart } from '../contexts/CartContext';
import { useAuth } from '../contexts/AuthContext';
import { FiStar, FiShoppingCart, FiMinus, FiPlus } from 'react-icons/fi';
import toast from 'react-hot-toast';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
export default function ProductDetail() {
  const { id } = useParams();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState('');
  const { addItem } = useCart();
  const { user } = useAuth();

  useEffect(() => {
    productApi.getOne(id).then(res => setProduct(res.data)).finally(() => setLoading(false));
  }, [id]);

  const handleAddToCart = () => {
    addItem(product, quantity);
    toast.success(`${quantity}x ${product.name} added to cart!`);
  };

  const handleReview = async (e) => {
    e.preventDefault();
    try {
      await reviewApi.create(product.id, { rating, comment });
      toast.success('Review submitted!');
      const res = await productApi.getOne(id);
      setProduct(res.data);
      setComment('');
    } catch {
      toast.error('Failed to submit review');
    }
  };

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;
  if (!product) return <div className="empty-state"><h3>Product not found</h3></div>;

  return (
    <div className="product-detail-page">
      <div className="detail-grid">
        <div className="detail-image">
          {product.image ? (
            <img src={product.image.startsWith('/') ? product.image : `${API_URL}/storage/${product.image}`} alt={product.name} />
          ) : (
            <div className="detail-placeholder">🍽️</div>
          )}
        </div>

        <div className="detail-info">
          <span className="detail-category">{product.category?.name}</span>
          <h1>{product.name}</h1>
          <p className="detail-desc">{product.description}</p>

          <div className="detail-meta">
            <div className="detail-rating">
              <FiStar className="star-icon" />
              <span>{Number(product.avg_rating).toFixed(1)}</span>
              <span className="review-count">({product.reviews?.length || 0} reviews)</span>
            </div>
            <span className="detail-orders">{product.order_count} orders</span>
          </div>

          <div className="detail-price">{formatPrice(product.price)}</div>

          <div className="detail-actions">
            <div className="qty-control">
              <button onClick={() => setQuantity(q => Math.max(1, q - 1))}><FiMinus /></button>
              <span>{quantity}</span>
              <button onClick={() => setQuantity(q => q + 1)}><FiPlus /></button>
            </div>
            <button className="add-cart-btn" onClick={handleAddToCart}>
              <FiShoppingCart /> Add to Cart — {formatPrice(product.price * quantity)}
            </button>
          </div>
        </div>
      </div>

      <section className="reviews-section">
        <h2>Reviews</h2>

        {user && (
          <form className="review-form" onSubmit={handleReview}>
            <div className="star-rating">
              {[1, 2, 3, 4, 5].map(star => (
                <button key={star} type="button" className={`star ${star <= rating ? 'active' : ''}`} onClick={() => setRating(star)}>
                  <FiStar />
                </button>
              ))}
            </div>
            <textarea placeholder="Write your review..." value={comment} onChange={(e) => setComment(e.target.value)} />
            <button type="submit" className="submit-review-btn">Submit Review</button>
          </form>
        )}

        <div className="reviews-list">
          {product.reviews?.length > 0 ? product.reviews.map(review => (
            <div key={review.id} className="review-item">
              <div className="review-header">
                <strong>{review.user?.name}</strong>
                <div className="review-stars">
                  {Array.from({ length: review.rating }, (_, i) => <FiStar key={i} className="star-icon" />)}
                </div>
              </div>
              <p>{review.comment}</p>
            </div>
          )) : (
            <p className="no-reviews">No reviews yet. Be the first to review!</p>
          )}
        </div>
      </section>
    </div>
  );
}
