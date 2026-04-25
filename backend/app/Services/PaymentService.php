<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Payment;
use Illuminate\Support\Str;

class PaymentService
{
    /**
     * Create a payment for an order.
     */
    public function createPayment(Order $order, string $method): Payment
    {
        $data = [
            'order_id' => $order->id,
            'method' => $method,
            'amount' => $order->total_amount,
            'status' => 'pending',
        ];

        if ($method === 'qris') {
            $data['qris_code'] = 'QRIS-' . strtoupper(Str::random(16));
        }

        if ($method === 'cash') {
            $data['status'] = 'paid';
            $data['paid_at'] = now();
        }

        return Payment::create($data);
    }

    /**
     * Simulate QRIS payment confirmation.
     */
    public function simulateQrisPayment(Payment $payment): Payment
    {
        $payment->update([
            'status' => 'paid',
            'paid_at' => now(),
        ]);

        $payment->order->update(['status' => 'confirmed']);

        return $payment->fresh();
    }
}
