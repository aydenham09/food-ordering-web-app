<?php

namespace Database\Seeders;

use App\Models\Review;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;

class ReviewSeeder extends Seeder
{
    public function run(): void
    {
        $customers = User::where('role', 'customer')->get();
        $products = Product::all();

        $comments = [
            'Absolutely delicious! Will order again.',
            'Great taste and generous portion.',
            'Good but could use a bit more seasoning.',
            'Amazing! Best food I have had in a while.',
            'Decent, nothing extraordinary.',
            'Love it! The flavor is on point.',
            'Very fresh and well-prepared.',
        ];

        foreach ($customers as $customer) {
            // Each customer reviews 3-5 random products
            $reviewProducts = $products->random(rand(3, min(5, $products->count())));

            foreach ($reviewProducts as $product) {
                Review::create([
                    'user_id' => $customer->id,
                    'product_id' => $product->id,
                    'rating' => rand(3, 5),
                    'comment' => $comments[array_rand($comments)],
                ]);
            }
        }

        // Recalculate scores after reviews
        Product::all()->each(fn(Product $p) => $p->recalculateScore());
    }
}
