<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index(): JsonResponse
    {
        $totalRevenue = Order::whereIn('status', ['confirmed', 'preparing', 'completed'])
            ->sum('total_amount');

        $totalOrders = Order::count();
        $totalProducts = Product::count();
        $totalCustomers = User::where('role', 'customer')->count();

        $recentOrders = Order::with(['user', 'payment'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        // ✅ FIX: Ganti strftime (SQLite) → MONTH/YEAR (MySQL)
        $monthlySales = Order::whereIn('status', ['confirmed', 'preparing', 'completed'])
            ->select(
                DB::raw('MONTH(created_at) as month'),
                DB::raw('YEAR(created_at) as year'),
                DB::raw('SUM(total_amount) as total'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy('year', 'month')
            ->orderBy('year')
            ->orderBy('month')
            ->limit(12)
            ->get();

        $popularProducts = Product::orderByDesc('order_count')
            ->limit(5)
            ->get();

        $ordersByStatus = Order::select('status', DB::raw('COUNT(*) as count'))
            ->groupBy('status')
            ->get();

        return response()->json([
            'total_revenue' => $totalRevenue,
            'total_orders' => $totalOrders,
            'total_products' => $totalProducts,
            'total_customers' => $totalCustomers,
            'recent_orders' => $recentOrders,
            'monthly_sales' => $monthlySales,
            'popular_products' => $popularProducts,
            'orders_by_status' => $ordersByStatus,
        ]);
    }
}