import { useState, useEffect } from 'react';
import { adminApi } from '../../api';
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi';
import toast from 'react-hot-toast';

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ name: '', email: '', password: '', role: 'customer' });
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');

  const fetchUsers = () => {
    adminApi.getUsers({ search, role: roleFilter }).then(res => setUsers(res.data.data)).finally(() => setLoading(false));
  };

  useEffect(() => { fetchUsers(); }, [search, roleFilter]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editing) {
        const data = { ...form };
        if (!data.password) delete data.password;
        await adminApi.updateUser(editing.id, data);
        toast.success('User updated!');
      } else {
        await adminApi.createUser(form);
        toast.success('User created!');
      }
      setShowModal(false);
      fetchUsers();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save user');
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('Delete this user?')) return;
    try {
      await adminApi.deleteUser(id);
      toast.success('User deleted!');
      fetchUsers();
    } catch { toast.error('Failed to delete'); }
  };

  if (loading) return <div className="loading-screen"><div className="spinner" /></div>;

  return (
    <div className="admin-crud-page">
      <div className="crud-header">
        <div className="header-title-group">
          <h1>Users</h1>
          <div className="header-filters">
            <input 
              type="text" 
              placeholder="Search by name or email..." 
              value={search} 
              onChange={e => setSearch(e.target.value)}
              className="admin-search-input"
            />
            <select 
              value={roleFilter} 
              onChange={e => setRoleFilter(e.target.value)}
              className="admin-select-input"
            >
              <option value="">All Roles</option>
              <option value="admin">Admin</option>
              <option value="customer">Customer</option>
            </select>
          </div>
        </div>
        <button className="btn-primary" onClick={() => { setEditing(null); setForm({ name: '', email: '', password: '', role: 'customer' }); setShowModal(true); }}>
          <FiPlus /> Add User
        </button>
      </div>

      <table className="admin-table">
        <thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Orders</th><th>Actions</th></tr></thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.name}</td>
              <td>{u.email}</td>
              <td><span className={`badge ${u.role === 'admin' ? 'badge-purple' : 'badge-blue'}`}>{u.role}</span></td>
              <td>{u.orders_count}</td>
              <td className="action-cell">
                <button className="icon-btn edit" onClick={() => { setEditing(u); setForm({ name: u.name, email: u.email, password: '', role: u.role }); setShowModal(true); }}><FiEdit /></button>
                <button className="icon-btn delete" onClick={() => handleDelete(u.id)}><FiTrash2 /></button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>{editing ? 'Edit User' : 'New User'}</h2>
            <form onSubmit={handleSubmit}>
              <div className="form-group"><label>Name</label><input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required /></div>
              <div className="form-group"><label>Email</label><input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} required /></div>
              <div className="form-group"><label>Password {editing && '(leave blank to keep)'}</label><input type="password" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} {...(!editing && { required: true })} /></div>
              <div className="form-group">
                <label>Role</label>
                <select value={form.role} onChange={e => setForm({ ...form, role: e.target.value })}>
                  <option value="customer">Customer</option>
                  <option value="admin">Admin</option>
                </select>
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
