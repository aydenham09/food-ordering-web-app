# FoodApp

FoodApp adalah aplikasi pemesanan makanan dengan backend Laravel dan frontend Flutter. Struktur, warna, dan alur UI Flutter dibuat mengikuti tampilan web sebelumnya, tetapi frontend aktif yang dipakai sekarang adalah `flutter_app`.

## Struktur Repo

```text
food-ordering-web-app/
|- backend/      -> Laravel REST API
|- flutter_app/  -> Flutter web frontend utama
|- frontend/     -> React lama / referensi sebelumnya
|- asset/        -> sumber asset gambar mentah
```

## Frontend Yang Dipakai

Frontend yang dipakai untuk pengembangan saat ini adalah:

- `flutter_app/` untuk Flutter Web

Folder `frontend/` masih ada sebagai peninggalan implementasi React sebelumnya, tetapi bukan frontend utama yang dipakai sekarang.

## Fitur Yang Sudah Ada di Flutter Web

- Landing page, menu, detail produk, cart, checkout, login, register
- Admin dashboard, produk, kategori, order, user, dan laporan
- Live search tanpa perlu menekan Enter
- Notifikasi add to cart di atas tengah
- Mini cart di header
- Validasi checkout: user harus login terlebih dahulu
- Demo credential dengan tombol copy / use
- Header blur transparan
- Integrasi ke backend Laravel API
- Asset gambar menu melalui `flutter_app/assets/catalog/`

## Teknologi

- Backend: Laravel 13, PHP 8.2+, SQLite
- Frontend utama: Flutter 3 / Dart 3
- State/UI Flutter: Provider, GoRouter, Dio, SharedPreferences

## Database Aktif

Environment backend saat ini memakai SQLite:

- koneksi: `sqlite`
- file database aktif: `backend/database/database.sqlite`

## Akun Demo

Setelah backend dijalankan dengan data seed / data lokal yang ada:

- Admin: `admin@foodapp.com` / `password`
- Customer: `john@example.com` / `password`

Di halaman login Flutter juga tersedia tombol untuk copy credential demo agar tidak perlu mengetik manual.

## Cara Menjalankan

### Prasyarat

Pastikan sudah tersedia:

- PHP 8.2+
- Composer
- Flutter SDK
- Chrome atau browser lain untuk Flutter web

### 1. Jalankan backend Laravel

Dari root project:

```powershell
cd backend
composer install
php artisan key:generate
php artisan migrate
php artisan serve
```

Backend akan aktif di:

```text
http://127.0.0.1:8000
```

API utamanya:

```text
http://127.0.0.1:8000/api
```

Catatan:

- Jika file `backend/.env` belum ada, salin dulu dari `.env.example`
- Jika `backend/database/database.sqlite` belum ada, buat file kosongnya terlebih dahulu

### 2. Jalankan frontend Flutter web

Buka terminal baru dari root project:

```powershell
cd flutter_app
flutter pub get
flutter run -d chrome
```

Flutter akan menjalankan web app di localhost dengan port yang tersedia otomatis.

## Cara Run Harian

Kalau project sudah pernah di-setup, biasanya cukup:

Terminal 1:

```powershell
cd backend
php artisan serve
```

Terminal 2:

```powershell
cd flutter_app
flutter run -d chrome
```

## Endpoint Penting

Beberapa endpoint yang dipakai frontend:

- `POST /api/register`
- `POST /api/login`
- `GET /api/products`
- `GET /api/categories`
- `GET /api/products/recommended`
- `GET /api/orders`
- `POST /api/orders`
- `GET /api/admin/dashboard`

## Catatan Penting

- `frontend/` React bukan frontend utama lagi
- `start.sh` masih mengarah ke backend + React lama, jadi belum merepresentasikan flow Flutter terbaru
- Untuk pengembangan saat ini, jalankan manual `backend/` dan `flutter_app/`
- Flutter mobile bisa ditambahkan dari basis kode `flutter_app` setelah versi web final

## Verifikasi Singkat

Jika semua berjalan normal:

- backend merespons di `http://127.0.0.1:8000/api/products`
- Flutter web terbuka di browser
- halaman menu menampilkan data dari backend Laravel
