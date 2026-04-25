import { useState, useEffect } from 'react';
import { adminApi } from '../../api';
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi';
import toast from 'react-hot-toast';

export default function Categories() {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [name, setName] = useState('');

  const fetchCategories = () => {
    adminApi.getCategories().then(res => setCategories(res.data)).finally(() => setLoading(false));
  };

  useEffect(() => { fetchCategories(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const data = new FormData();
      data.append('name', name);

      if (editing) {
        data.append('_method', 'PUT');
        await adminApi.updateCategory(editing.id, data);
        toast.success('Category updated!');
      } else {
        await adminApi.createCategory(data);
        toast.success('Category created!');
      }
      setShowModal(false);
      fetchCategories();
    } catch { toast.error('Failed to save category'); }
  };

  const handleDelete = async (id) => {
    if (!confirm('Delete this category?')) return;
    try {
      await adminApi.deleteCategory(id);
      toast.success('Category deleted!');
      fetchCategories();
    } catch { toast.error('Failed to delete'); }
  };

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  return (
    <div className="admin-crud-page">
      <div className="crud-header">
        <h1>Categories</h1>
        <button className="btn-primary" onClick={() => { setEditing(null); setName(''); setShowModal(true); }}><FiPlus /> Add Category</button>
      </div>

      <table className="admin-table">
        <thead><tr><th>Name</th><th>Slug</th><th>Products</th><th>Actions</th></tr></thead>
        <tbody>
          {categories.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.slug}</td>
              <td>{c.products_count}</td>
              <td className="action-cell">
                <button className="icon-btn edit" onClick={() => { setEditing(c); setName(c.name); setShowModal(true); }}><FiEdit /></button>
                <button className="icon-btn delete" onClick={() => handleDelete(c.id)}><FiTrash2 /></button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>{editing ? 'Edit Category' : 'New Category'}</h2>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Name</label>
                <input value={name} onChange={e => setName(e.target.value)} required />
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
