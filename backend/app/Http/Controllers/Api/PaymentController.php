<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function pay(Request $request, Order $order, PaymentService $paymentService): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($order->payment) {
            return response()->json(['message' => 'Payment already exists for this order'], 422);
        }

        $validated = $request->validate([
            'method' => 'required|in:cash,qris',
        ]);

        $payment = $paymentService->createPayment($order, $validated['method']);

        if ($validated['method'] === 'cash') {
            $order->update(['status' => 'confirmed']);
        }

        $order->load('payment');

        return response()->json($order);
    }

    public function simulateQris(Request $request, Order $order, PaymentService $paymentService): JsonResponse
    {
        if ($order->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $payment = $order->payment;

        if (!$payment || $payment->method !== 'qris') {
            return response()->json(['message' => 'No QRIS payment found for this order'], 422);
        }

        if ($payment->status === 'paid') {
            return response()->json(['message' => 'Payment already confirmed'], 422);
        }

        $paymentService->simulateQrisPayment($payment);

        $order->load('payment');

        return response()->json([
            'message' => 'QRIS payment confirmed successfully',
            'order' => $order,
        ]);
    }
}
