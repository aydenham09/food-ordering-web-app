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
    await delay(300);
    let filtered = MOCK_PRODUCTS;
    if (params?.category) filtered = MOCK_PRODUCTS.filter(p => p.category_id == params.category);
    if (params?.search) filtered = MOCK_PRODUCTS.filter(p => p.name.toLowerCase().includes(params.search.toLowerCase()));
    return { data: { data: filtered, last_page: 1, current_page: 1 } };
  },
  getOne: async (id) => {
    await delay(300);
    return { data: MOCK_PRODUCTS.find(p => p.id == id) };
  },
  getRecommended: async () => {
    await delay(300);
    return { data: MOCK_PRODUCTS.filter(p => p.is_recommended) };
  },
};

export const categoryApi = {
  getAll: async () => {
    await delay(300);
    return { data: MOCK_CATEGORIES };
  },
  getOne: async (id) => {
    await delay(300);
    return { data: MOCK_CATEGORIES.find(c => c.id == id) };
  },
};

export const orderApi = {
  getAll: async () => {
    await delay(300);
    return { data: { data: getMockOrders() } };
  },
  getOne: async (id) => {
    await delay(300);
    return { data: getMockOrders().find(o => o.id == id) };
  },
  create: async (data) => {
    await delay(500);
    const id = Date.now();
    const newOrder = {
      id: id,
      order_number: `ORD-${id.toString().slice(-6)}`,
      total_amount: data.items.reduce((sum, item) => sum + (item.price * item.quantity), 0),
      status: 'pending',
      items: data.items.map(item => ({
        ...item, 
        product: MOCK_PRODUCTS.find(p => p.id === item.product_id),
        subtotal: item.price * item.quantity
      })),
      payment: {
        method: data.payment_method,
        status: 'pending',
        qris_code: '00020101021226590014ID.CO.QRIS.WWW0118936000140000000000021500000000000000000303UME51440014ID.CO.QRIS.WWW02150000000000000005204731153033605802ID5911FoodApp Mock6009Jakarta6105123456304CA43'
      },
      created_at: new Date().toISOString()
    };
    const orders = getMockOrders();
    orders.unshift(newOrder); // Add to beginning
    saveMockOrders(orders);
    return { data: newOrder };
  },
};

export const paymentApi = {
  pay: async (orderId) => {
    await delay(500);
    const orders = getMockOrders();
    const order = orders.find(o => o.id == orderId);
    if(order) order.status = 'completed';
    saveMockOrders(orders);
    return { data: { message: 'Payment successful' } };
  },
  simulateQris: async (orderId) => {
    await delay(500);
    const orders = getMockOrders();
    const order = orders.find(o => o.id == orderId);
    if(order) {
      order.status = 'completed';
      if(order.payment) order.payment.status = 'paid';
    }
    saveMockOrders(orders);
    return { data: { message: 'Payment successful' } };
  },
};

export const reviewApi = {
  create: async () => {
    await delay(300);
    return { data: { message: 'Review added' } };
  },
};

export const adminApi = {
  getDashboard: async () => {
    const orders = getMockOrders();
    // Group orders by status for the pie chart
    const statusCounts = orders.reduce((acc, o) => {
      acc[o.status] = (acc[o.status] || 0) + 1;
      return acc;
    }, {});
    const orders_by_status = Object.entries(statusCounts).map(([status, count]) => ({ status, count }));

    return { 
      data: { 
        total_orders: orders.length, 
        total_revenue: orders.reduce((s,o)=>s+o.total_amount,0), 
        total_products: MOCK_PRODUCTS.length,
        total_customers: 1,
        pending_orders: orders.filter(o=>o.status==='pending').length, 
        orders_by_status: orders_by_status.length ? orders_by_status : [{status: 'No Orders', count: 1}],
        popular_products: MOCK_PRODUCTS.map(p => ({ name: p.name, order_count: p.order_count })),
        recent_orders: orders.slice(0,5) 
      } 
    };
  },
  getProducts: async () => ({ data: { data: MOCK_PRODUCTS } }),
  getCategories: async () => ({ data: MOCK_CATEGORIES }),
  getOrders: async () => ({ data: { data: getMockOrders() } }),
  getUsers: async () => ({ data: { data: [{id: 1, name: 'Admin', email: 'admin@foodapp.com', role: 'admin', orders_count: 0}] } }),
  getSalesReport: async () => ({ data: { total_revenue: 0, total_orders: 0, sales: [] } }),
  getPopularReport: async () => ({ data: MOCK_PRODUCTS.map(p => ({ name: p.name, order_count: p.order_count })) }),
};

export default api;
