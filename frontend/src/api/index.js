import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const authApi = {
  register: (data) => api.post('/register', data),
  login: (data) => api.post('/login', data),
  logout: () => api.post('/logout'),
  getUser: () => api.get('/user'),
};

const MOCK_CATEGORIES = [
  { id: 1, name: 'Main Course', slug: 'main-course', products_count: 1 },
  { id: 2, name: 'Specials', slug: 'specials', products_count: 1 },
  { id: 3, name: 'Desserts', slug: 'desserts', products_count: 1 },
  { id: 4, name: 'Beverages', slug: 'beverages', products_count: 1 },
];

const MOCK_PRODUCTS = [
  {
    id: 1, category_id: 1, category: {name: 'Main Course'},
    name: 'Gourmet Angus Burger', 
    description: 'A luxurious gourmet burger with Angus beef on a dark slate slate, dramatic lighting, fine dining presentation. Served with handmade truffle fries.',
    price: 185000, image: '/images/burger.png',
    avg_rating: 4.8, order_count: 120, is_recommended: true
  },
  {
    id: 2, category_id: 2, category: {name: 'Specials'},
    name: 'Black Truffle Tagliatelle', 
    description: 'A plate of premium truffle pasta with fresh parmesan shavings. Prepared with handmade tagliatelle and aged cheese.',
    price: 245000, image: '/images/pasta.png',
    avg_rating: 4.9, order_count: 85, is_recommended: true
  },
  {
    id: 3, category_id: 3, category: {name: 'Desserts'},
    name: 'Gold Leaf Chocolate Mousse', 
    description: 'Luxurious dark chocolate mousse layered dessert topped with edible 24k gold leaf. Rich, dark aesthetics with amber lighting accents.',
    price: 120000, image: '/images/dessert.png',
    avg_rating: 4.7, order_count: 200, is_recommended: true
  },
  {
    id: 4, category_id: 4, category: {name: 'Beverages'},
    name: 'Smoked Rosemary Old Fashioned', 
    description: 'An elegant craft cocktail with a smoked rosemary sprig, amber colored liquid in a crystal glass.',
    price: 155000, image: '/images/drink.png',
    avg_rating: 4.9, order_count: 150, is_recommended: true
  }
];

// Use localStorage for mock orders persistence
const getMockOrders = () => JSON.parse(localStorage.getItem('mockOrders') || '[]');
const saveMockOrders = (orders) => localStorage.setItem('mockOrders', JSON.stringify(orders));

const delay = (ms) => new Promise(res => setTimeout(res, ms));

export const productApi = {
  getAll: async (params) => {
    const apiParams = { ...params };
    if (apiParams.category) {
      apiParams.category_id = apiParams.category;
      delete apiParams.category;
    }
    return api.get('/products', { params: apiParams });
  },
  getOne: async (id) => api.get(`/products/${id}`),
  getRecommended: async () => api.get('/products/recommended'),
};

export const categoryApi = {
  getAll: async () => api.get('/categories'),
  getOne: async (id) => api.get(`/categories/${id}`),
};

export const orderApi = {
  getAll: async () => api.get('/orders'),
  getOne: async (id) => api.get(`/orders/${id}`),
  create: async (data) => api.post('/orders', data),
};

export const paymentApi = {
  pay: async (orderId) => api.post(`/payments/${orderId}/pay`),
  simulateQris: async (orderId) => api.post(`/payments/${orderId}/simulate-qris`),
};

export const reviewApi = {
  create: async (productId, data) => api.post(`/products/${productId}/reviews`, data),
};

export const adminApi = {
  getDashboard: async () => api.get('/admin/dashboard'),
  getProducts: async () => api.get('/admin/products'),
  createProduct: async (data) => api.post('/admin/products', data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  updateProduct: async (id, data) => api.post(`/admin/products/${id}`, data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  deleteProduct: async (id) => api.delete(`/admin/products/${id}`),
  getCategories: async () => api.get('/admin/categories'),
  createCategory: async (data) => api.post('/admin/categories', data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  updateCategory: async (id, data) => api.post(`/admin/categories/${id}`, data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  deleteCategory: async (id) => api.delete(`/admin/categories/${id}`),
  getOrders: async () => api.get('/admin/orders'),
  getOrder: async (id) => api.get(`/admin/orders/${id}`),
  updateOrderStatus: async (id, status) => api.patch(`/admin/orders/${id}/status`, { status }),
  getUsers: async (params) => api.get('/admin/users', { params }),
  getSalesReport: async () => api.get('/admin/reports/sales'),
  getPopularReport: async () => api.get('/admin/reports/popular'),
};

export default api;
