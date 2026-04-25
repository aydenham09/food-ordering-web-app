import { useState, useEffect, useRef } from 'react';
import { adminApi, categoryApi } from '../../api';
import { FiPlus, FiEdit, FiTrash2, FiUpload, FiX } from 'react-icons/fi';
import toast from 'react-hot-toast';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export default function Products() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ name: '', description: '', price: '', category_id: '', is_available: true, image: null });
  const [imagePreview, setImagePreview] = useState(null);
  const fileInputRef = useRef(null);

  const fetchProducts = () => {
    adminApi.getProducts().then(res => setProducts(res.data.data)).finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchProducts();
    categoryApi.getAll().then(res => setCategories(res.data));
  }, []);

  const formatPrice = (price) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(price);

  const openCreate = () => {
    setEditing(null);
    setForm({ name: '', description: '', price: '', category_id: categories[0]?.id || '', is_available: true, image: null });
    setImagePreview(null);
    setShowModal(true);
  };

  const openEdit = (product) => {
    setEditing(product);
    setForm({ name: product.name, description: product.description || '', price: product.price, category_id: product.category_id, is_available: product.is_available, image: null });
    setImagePreview(product.image ? (product.image.startsWith('/') ? product.image : `${API_URL}/storage/${product.image}`) : null);
    setShowModal(true);
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        toast.error('Image must be less than 2MB');
        return;
      }
      setForm({ ...form, image: file });
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const removeImage = () => {
    setForm({ ...form, image: null });
    setImagePreview(editing?.image ? `${API_URL}/storage/${editing.image}` : null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const data = new FormData();
      Object.entries(form).forEach(([k, v]) => {
        if (k === 'image') {
          if (v instanceof File) data.append('image', v);
        } else if (k === 'is_available') {
          data.append(k, v ? 1 : 0);
        } else if (v !== null && v !== undefined) {
          data.append(k, v);
        }
      });

      if (editing) {
        data.append('_method', 'PUT');
        await adminApi.updateProduct(editing.id, data);
        toast.success('Product updated!');
      } else {
        await adminApi.createProduct(data);
        toast.success('Product created!');
      }
      setShowModal(false);
      fetchProducts();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save product');
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('Delete this product?')) return;
    try {
      await adminApi.deleteProduct(id);
      toast.success('Product deleted!');
      fetchProducts();
    } catch { toast.error('Failed to delete'); }
  };

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  return (
    <div className="admin-crud-page">
      <div className="crud-header">
        <h1>Products</h1>
        <button className="btn-primary" onClick={openCreate}><FiPlus /> Add Product</button>
      </div>

      <table className="admin-table">
        <thead>
          <tr><th>Image</th><th>Name</th><th>Category</th><th>Price</th><th>Orders</th><th>Rating</th><th>Available</th><th>Actions</th></tr>
        </thead>
        <tbody>
          {products.map(p => (
            <tr key={p.id}>
              <td>
                {p.image ? (
                  <img src={p.image.startsWith('/') ? p.image : `${API_URL}/storage/${p.image}`} alt={p.name} style={{ width: 48, height: 48, objectFit: 'cover', borderRadius: 8 }} />
                ) : (
                  <div style={{ width: 48, height: 48, borderRadius: 8, background: 'var(--bg-tertiary, #2a2a3e)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20 }}>🍽️</div>
                )}
              </td>
              <td>{p.name}</td>
              <td>{p.category?.name}</td>
              <td>{formatPrice(p.price)}</td>
              <td>{p.order_count}</td>
              <td>⭐ {Number(p.avg_rating).toFixed(1)}</td>
              <td><span className={`badge ${p.is_available ? 'badge-green' : 'badge-red'}`}>{p.is_available ? 'Yes' : 'No'}</span></td>
              <td className="action-cell">
                <button className="icon-btn edit" onClick={() => openEdit(p)}><FiEdit /></button>
                <button className="icon-btn delete" onClick={() => handleDelete(p.id)}><FiTrash2 /></button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>{editing ? 'Edit Product' : 'New Product'}</h2>
            <form onSubmit={handleSubmit}>
              {/* Image Upload */}
              <div className="form-group">
                <label>Product Image</label>
                <div className="image-upload-area">
                  {imagePreview ? (
                    <div className="image-preview-container">
                      <img src={imagePreview} alt="Preview" className="image-preview" />
                      <button type="button" className="image-remove-btn" onClick={removeImage} title="Remove image">
                        <FiX />
                      </button>
                    </div>
                  ) : (
                    <div className="image-upload-placeholder" onClick={() => fileInputRef.current?.click()}>
                      <FiUpload size={28} />
                      <span>Click to upload image</span>
                      <span className="image-upload-hint">Max 2MB · JPG, PNG, WEBP</span>
                    </div>
                  )}
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/jpeg,image/png,image/webp"
                    onChange={handleImageChange}
                    style={{ display: 'none' }}
                  />
                  {imagePreview && (
                    <button type="button" className="btn-secondary btn-sm" onClick={() => fileInputRef.current?.click()} style={{ marginTop: 8 }}>
                      Change Image
                    </button>
                  )}
                </div>
              </div>

              <div className="form-group">
                <label>Name</label>
                <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>Category</label>
                <select value={form.category_id} onChange={e => setForm({ ...form, category_id: e.target.value })} required>
                  {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label>Price (IDR)</label>
                <input type="number" value={form.price} onChange={e => setForm({ ...form, price: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>Description</label>
                <textarea value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
              </div>
              <div className="form-group checkbox">
                <label>
                  <input type="checkbox" checked={form.is_available} onChange={e => setForm({ ...form, is_available: e.target.checked })} />
                  Available
                </label>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn-primary">{editing ? 'Update' : 'Create'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
