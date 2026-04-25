import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { productApi, categoryApi } from '../api';
import ProductCard from '../components/ProductCard';
import { FiSearch } from 'react-icons/fi';

export default function Menu() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [activeCategory, setActiveCategory] = useState(searchParams.get('category') || '');
  const [page, setPage] = useState(1);
  const [lastPage, setLastPage] = useState(1);

  useEffect(() => {
    categoryApi.getAll().then(res => setCategories(res.data));
  }, []);

  useEffect(() => {
    setLoading(true);
    const params = { page };
    if (search) params.search = search;
    if (activeCategory) params.category_id = activeCategory;

    productApi.getAll(params).then(res => {
      setProducts(res.data.data);
      setLastPage(res.data.last_page);
    }).finally(() => setLoading(false));
  }, [search, activeCategory, page]);

  const handleCategoryClick = (catId) => {
    const newCat = activeCategory === String(catId) ? '' : String(catId);
    setActiveCategory(newCat);
    setPage(1);
    if (newCat) searchParams.set('category', newCat);
    else searchParams.delete('category');
    setSearchParams(searchParams);
  };

  const handleSearch = (e) => {
    e.preventDefault();
    setPage(1);
    if (search) searchParams.set('search', search);
    else searchParams.delete('search');
    setSearchParams(searchParams);
  };

  return (
    <div className="menu-page">
      <div className="menu-header">
        <h1>Our Menu</h1>
        <form onSubmit={handleSearch} className="menu-search">
          <FiSearch />
          <input
            type="text"
            placeholder="Search menu..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </form>
      </div>

      <div className="category-filters">
        <button
          className={`filter-btn ${!activeCategory ? 'active' : ''}`}
          onClick={() => handleCategoryClick('')}
        >
          All
        </button>
        {categories.map(cat => (
          <button
            key={cat.id}
            className={`filter-btn ${activeCategory === String(cat.id) ? 'active' : ''}`}
            onClick={() => handleCategoryClick(cat.id)}
          >
            {cat.name}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="loading-screen"><div className="spinner" /></div>
      ) : products.length > 0 ? (
        <>
          <div className="product-grid">
            {products.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>

          {lastPage > 1 && (
            <div className="pagination">
              <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Previous</button>
              <span>Page {page} of {lastPage}</span>
              <button disabled={page >= lastPage} onClick={() => setPage(p => p + 1)}>Next</button>
            </div>
          )}
        </>
      ) : (
        <div className="empty-state">
          <span className="empty-icon">🔍</span>
          <h3>No products found</h3>
          <p>Try a different search or category</p>
        </div>
      )}
    </div>
  );
}
