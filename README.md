#FoodOrderingWebApp

A full-stack food ordering web application built using Laravel 13 as the backend API and React 19 as the frontend. This application supports product management, categories, an ordering system, and even QRIS payment simulation.

## 🚀 Core Technologies

### Backend (Laravel)
- **Framework:** Laravel 13
- **Authentication:** Laravel Sanctum
- **Database:** SQLite (Default)
- **API Features:** - RESTful API for Products & Categories
- Order & Review Management
- Admin Dashboard & Sales Reporting
- Product Recommendation System

### Frontend (React)
- **Framework:** React 19 (Vite)
- **Routing:** React Router DOM v7
- **State Management & Fetching:** Axios
- **UI Components:** Recharts (for reports), React Icons, React Hot Toast
- **Special Features:** `qrcode.react` integration for QRIS payment simulation.

## 🛠️ Application Features

- **User Side:**
- Account Registration and Login.
- Browse products by category.
- Get product recommendations.
- Place orders and view order history.
- Simulate payment via QRIS.
- Provide reviews on purchased products.

- **Admin Side:**
- Statistics dashboard.
- Product and Category CRUD management.
- Update customer order status.
- User data management.
- Sales and popular product reports.

## 📦 Installation

### Prerequisites
- PHP >= 8.3
- Node.js & NPM
- Composer

### Setup Steps

1. **Clone Repository**
```bash
git clone <repository-url>
cd food-ordering-web-app
```

2. **Backend Setup**
This repository provides an automated script to simplify setup:
```bash
cd backend
composer run setup
```
This script will run: `composer install`, copy `.env`, generate keys, migrate databases, and install NPM backend dependencies.

3. **Frontend Setup**
```bash
cd frontend
npm install
```

## 🖥️ Running the Application

To run both services (Backend & Frontend) simultaneously, you can use the following command in the **backend** directory:

```bash
composer run dev
```
This command will run the Laravel server, queue, log pool, and Vite in parallel using `concurrently`.

Or separately:
- **Backend:** `php artisan serve` inside the `backend` folder.
- **Frontend:** `npm run dev` inside the `frontend` folder.

## 📂 Main Folder Structure

- `/backend`: Contains API logic, database models (User, Product, Order, etc.), and payment integration.

- `/frontend`: Contains the user interface, React components, and application state management.

## 📝 Important Note
This application uses a token-based authentication system (Sanctum). Be sure to include the `Bearer Token` in the header of every API request that requires authentication.
