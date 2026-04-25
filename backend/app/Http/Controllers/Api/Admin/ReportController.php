<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function sales(Request $request): JsonResponse
    {
        $days = $request->get('days', 30);

        $sales = Order::whereIn('status', ['confirmed', 'preparing', 'completed'])
            ->where('created_at', '>=', now()->subDays($days))
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(total_amount) as total'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $totalRevenue = $sales->sum('total');
        $totalOrders = $sales->sum('count');

        return response()->json([
            'sales' => $sales,
            'total_revenue' => $totalRevenue,
            'total_orders' => $totalOrders,
        ]);
    }

    public function popular(): JsonResponse
    {
        $popular = Product::select('products.*')
            ->withCount('orderItems')
            ->orderByDesc('order_items_count')
            ->limit(10)
            ->get();

        return response()->json($popular);
    }
}
