<?php

namespace Database\Seeders;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        $customers = User::where('role', 'customer')->get();
        $products = Product::all();

        $statuses = ['completed', 'confirmed', 'preparing', 'completed', 'pending'];

        foreach ($customers as $index => $customer) {
            // Each customer gets 1-2 orders
            $numOrders = $index === 0 ? 2 : 1;

            for ($i = 0; $i < $numOrders; $i++) {
                $selectedProducts = $products->random(rand(2, 4));
                $totalAmount = 0;
                $items = [];

                foreach ($selectedProducts as $product) {
                    $qty = rand(1, 3);
                    $subtotal = $product->price * $qty;
                    $totalAmount += $subtotal;

                    $items[] = [
                        'product_id' => $product->id,
                        'quantity' => $qty,
                        'price' => $product->price,
                        'subtotal' => $subtotal,
                    ];
                }

                $status = $statuses[($index * $numOrders + $i) % count($statuses)];

                $order = Order::create([
                    'user_id' => $customer->id,
                    'total_amount' => $totalAmount,
                    'status' => $status,
                    'notes' => $i === 0 ? 'Extra spicy please' : null,
                    'created_at' => now()->subDays(rand(0, 14)),
                ]);

                $order->items()->createMany($items);

                $method = $i % 2 === 0 ? 'cash' : 'qris';
                Payment::create([
                    'order_id' => $order->id,
                    'method' => $method,
                    'amount' => $totalAmount,
                    'status' => in_array($status, ['confirmed', 'preparing', 'completed']) ? 'paid' : 'pending',
                    'qris_code' => $method === 'qris' ? 'QRIS-SAMPLE' . $order->id : null,
                    'paid_at' => in_array($status, ['confirmed', 'preparing', 'completed']) ? now()->subDays(rand(0, 14)) : null,
                ]);
            }
        }
    }
}
