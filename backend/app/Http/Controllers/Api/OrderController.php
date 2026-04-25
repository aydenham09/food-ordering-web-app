<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $orders = $request->user()
            ->orders()
            ->with(['items.product', 'payment'])
            ->orderByDesc('created_at')
            ->paginate(10);

        return response()->json($orders);
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $order->load(['items.product', 'payment']);

        return response()->json($order);
    }

    public function store(Request $request, PaymentService $paymentService): JsonResponse
    {
        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'payment_method' => 'required|in:cash,qris',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request, $validated, $paymentService) {
            $totalAmount = 0;
            $orderItems = [];

            foreach ($validated['items'] as $item) {
                $product = Product::findOrFail($item['product_id']);

                if (!$product->is_available) {
                    return response()->json([
                        'message' => "Product '{$product->name}' is not available",
                    ], 422);
                }

                $subtotal = $product->price * $item['quantity'];
                $totalAmount += $subtotal;

                $orderItems[] = [
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'price' => $product->price,
                    'subtotal' => $subtotal,
                ];

                // Increment order count for scoring
                $product->increment('order_count', $item['quantity']);
                $product->recalculateScore();
            }

            $order = Order::create([
                'user_id' => $request->user()->id,
                'total_amount' => $totalAmount,
                'status' => 'pending',
                'notes' => $validated['notes'] ?? null,
            ]);

            $order->items()->createMany($orderItems);

            // Create payment
            $payment = $paymentService->createPayment($order, $validated['payment_method']);

            // If cash, confirm order directly
            if ($validated['payment_method'] === 'cash') {
                $order->update(['status' => 'confirmed']);
            }

            $order->load(['items.product', 'payment']);

            return response()->json($order, 201);
        });
    }
}
