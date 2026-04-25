import { createContext, useContext, useState, useEffect } from 'react';
import { authApi } from '../api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (token) {
      // Mock validating user with existing token
      const savedUser = localStorage.getItem('user');
      if (savedUser) {
        setUser(JSON.parse(savedUser));
      } else {
        setToken(null);
        localStorage.removeItem('token');
      }
      setLoading(false);
    } else {
      setLoading(false);
    }
  }, [token]);

  const login = async (credentials) => {
    // Mock login taking email and password
    const mockUser = {
      id: 1,
      name: credentials.email === 'admin@foodapp.com' ? 'Admin' : 'Mock User',
      email: credentials.email,
      role: credentials.email === 'admin@foodapp.com' ? 'admin' : 'customer'
    };
    const mockToken = 'mock-jwt-token-12345';
    
    localStorage.setItem('token', mockToken);
    localStorage.setItem('user', JSON.stringify(mockUser));
    setToken(mockToken);
    setUser(mockUser);
    return { token: mockToken, user: mockUser };
  };

  const register = async (data) => {
    // Mock register
    const mockUser = {
      id: 2,
      name: data.name,
      email: data.email,
      role: 'customer'
    };
    const mockToken = 'mock-jwt-token-67890';

    localStorage.setItem('token', mockToken);
    localStorage.setItem('user', JSON.stringify(mockUser));
    setToken(mockToken);
    setUser(mockUser);
    return { token: mockToken, user: mockUser };
  };

  const logout = async () => {
    // Mock logout
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, loading, login, register, logout, isAdmin: user?.role === 'admin' }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
