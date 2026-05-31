# FoodApp - Food Ordering Web App

## Deskripsi Proyek

FoodApp adalah proyek tugas ABP Kelompok 4 berupa sistem pemesanan makanan yang dirancang untuk mendukung ekosistem cross-platform. Fokus repo ini adalah versi web yang terdiri dari frontend React untuk pelanggan dan admin, serta backend Laravel sebagai REST API terpusat.

Secara konsep, aplikasi ini dibuat untuk menjawab kebutuhan operasional restoran yang fleksibel:

- pelanggan dapat melihat menu, menambahkan item ke keranjang, checkout (dengan opsi spesifik seperti Delivery, Dine-in, atau Takeaway), dan melihat riwayat pesanan;
- admin atau kasir dapat memantau pesanan, mengelola produk dan kategori, serta melihat ringkasan penjualan;
- seluruh alur diarahkan ke satu backend agar data tetap konsisten dan mudah dikembangkan ke platform lain, termasuk mobile app pendamping.

## Tujuan Project

- Membangun sistem pemesanan makanan dengan pemisahan peran `customer` dan `admin`
- Menyediakan backend REST API sebagai pusat data aplikasi
- Menyiapkan antarmuka web untuk pemesanan, pembayaran, dan pengelolaan data restoran
- Menjadi fondasi integrasi lintas platform untuk web dan mobile

## Fitur Utama

### Sisi Customer
- Registrasi dan login
- Melihat daftar menu dan detail produk
- Menambahkan produk ke cart
- Checkout pesanan dengan opsi pengambilan:
  - Takeaway
  - Dine-in (input nomor meja)
  - Delivery (input alamat lengkap & opsional upload foto lokasi penurunan)
- Simulasi pembayaran QRIS
- Melihat riwayat order
- Memberikan review produk

### Sisi Admin
- Dashboard statistik
- CRUD produk (termasuk upload gambar)
- CRUD kategori
- Monitoring dan update status pesanan (lengkap dengan tipe pesanan, alamat, dan nomor meja)
- Manajemen user
- Laporan penjualan bulanan dan produk populer

## Arsitektur Repo

```text
food-ordering-web-app/
|- backend/   -> Laravel 13 REST API
|- frontend/  -> React 19 + Vite web client
```

## Teknologi yang Digunakan

- Backend: Laravel 13, PHP 8.2+, Sanctum
- Frontend: React 19, Vite, React Router
- HTTP Client: Axios
- UI Support: React Hot Toast, React Icons, Recharts, QR Code React
- Database default: SQLite
- Database live: PostgreSQL (Supabase)

## Catatan Kondisi Implementasi Saat Ini

README ini mengikuti kondisi kode yang ada saat ini, bukan hanya rencana di laporan:

- backend sudah menyediakan REST API untuk auth, produk, kategori, order, payment, review, dan admin;
- frontend web sudah memiliki alur halaman customer dan admin;
- frontend saat ini masih memakai mock data untuk produk, kategori, order, payment, dan dashboard admin;
- autentikasi frontend juga masih disimulasikan di sisi client;
- karena itu, repo ini paling tepat dibaca sebagai progres web + API, dengan arah pengembangan menuju integrasi penuh.

**Update Terkini (Integrasi Final):**
- Saat ini frontend **sudah sepenuhnya terintegrasi** dengan backend Laravel dan menggunakan database PostgreSQL (Supabase) secara langsung.
- *Mock data* sudah sepenuhnya dilepas, semua grafik penjualan, halaman laporan, manajemen pesanan, dan menu pelanggan menarik data *real-time* yang sama dari server.

## Akun Demo

### Seed backend

Setelah menjalankan seeder backend, akun berikut tersedia:

- Admin: `admin@foodapp.com` / `password`
- Customer: `john@example.com` / `password`

### Frontend saat ini

Karena login frontend masih mock:

- gunakan email `admin@foodapp.com` untuk masuk sebagai admin;
- gunakan email lain apa pun untuk masuk sebagai customer;
- password saat ini tidak divalidasi oleh frontend mock.

*(Catatan: Setelah pembaruan integrasi final, login sekarang tervalidasi ke database. Silakan gunakan password yang sesuai di atas).*

## Tutorial Menjalankan Project

### Prasyarat

Pastikan perangkat sudah memiliki:

- PHP 8.2 atau lebih baru
- Composer
- Node.js dan npm

### 🚀 Cara Cepat (Rekomendasi)

Untuk mempermudah teman-teman saat pertama kali melakukan clone repository, tersedia script setup yang akan otomatis menginstal semuanya dan langsung menyalakan server.

Buka terminal di root project dan jalankan:
```bash
./start.sh
```
*(Script ini otomatis akan melakukan composer install, npm install, copy .env, migrate database, membuat storage link, lalu menjalankan `php artisan serve` dan `npm run dev` bersamaan. Cukup tekan `Ctrl+C` untuk mematikan).*

---

### Cara Manual

### 1. Clone dan masuk ke project

```bash
git clone <repository-url>
cd food-ordering-web-app
```

### 2. Setup backend Laravel

Masuk ke folder backend:

```bash
cd backend
```

Install dependency PHP:

```bash
composer install
```

Salin file environment:

```bash
copy .env.example .env
```

Buat file database SQLite:

```bash
type nul > database\database.sqlite
```

Generate app key:

```bash
php artisan key:generate
```

Jalankan migrasi dan seeder:

```bash
php artisan migrate --seed
```

Tautkan storage lokal:

```bash
php artisan storage:link
```

Install dependency frontend internal Laravel untuk Vite backend:

```bash
npm install
```

### 3. Setup frontend React

Buka terminal baru lalu masuk ke folder frontend:

```bash
cd frontend
npm install
```

Jika ingin eksplisit menentukan URL backend, buat file `.env` di folder `frontend`:

```env
VITE_API_URL=http://127.0.0.1:8000
```

Tanpa file ini, frontend akan memakai default `http://localhost:8000`.

### 4. Jalankan aplikasi

Project ini dijalankan dengan 2 terminal terpisah.

Terminal 1, untuk backend Laravel:

```bash
cd backend
php artisan serve
```

Terminal 2, untuk frontend React:

```bash
cd frontend
npm run dev
```

Setelah itu akses:

- Frontend: `http://localhost:5173`
- Backend API: `http://127.0.0.1:8000/api`

## Alternatif Menjalankan Backend

Di folder `backend`, tersedia script:

```bash
composer run dev
```

Perintah ini menjalankan server Laravel, queue listener, log watcher, dan Vite untuk backend Laravel. Namun, perintah ini tidak menjalankan frontend React di folder `frontend`, jadi frontend tetap perlu dijalankan terpisah dengan `npm run dev`.

## Endpoint Backend yang Sudah Tersedia

Beberapa endpoint utama yang sudah ada:

- `POST /api/register`
- `POST /api/login`
- `GET /api/products`
- `GET /api/categories`
- `GET /api/products/recommended`
- `GET /api/orders`
- `POST /api/orders`
- `POST /api/payments/{order}/simulate-qris`
- `GET /api/admin/dashboard`

## Ringkasan

Repo ini merepresentasikan bagian web dari proyek ABP FoodApp: sebuah sistem pemesanan makanan dengan peran customer dan admin, backend API terpusat, serta arah pengembangan menuju integrasi penuh lintas platform. Jika dibutuhkan, README ini masih bisa dilanjutkan dengan section deployment, ERD, atau dokumentasi API per endpoint.
