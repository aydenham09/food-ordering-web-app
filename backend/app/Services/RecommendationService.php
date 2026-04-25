<?php

namespace App\Services;

use App\Models\Product;
use App\Models\Order;
use Illuminate\Support\Collection;

class RecommendationService
{
    /**
     * Get top recommended products by score.
     * score = (order_count * 0.6) + (avg_rating * 0.4)
     */
    public function getTopProducts(int $limit = 8): Collection
    {
        return Product::where('is_available', true)
            ->orderByDesc('score')
            ->limit($limit)
            ->get();
    }

    /**
     * Personalized recommendations based on user's past orders.
     */
    public function getPersonalized(int $userId, int $limit = 8): Collection
    {
        // Get categories user has ordered from
        $orderedCategoryIds = Order::where('user_id', $userId)
            ->join('order_items', 'orders.id', '=', 'order_items.order_id')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->pluck('products.category_id')
            ->unique();

        if ($orderedCategoryIds->isEmpty()) {
            return $this->getTopProducts($limit);
        }

        // Get products from those categories, excluding already ordered
        $orderedProductIds = Order::where('user_id', $userId)
            ->join('order_items', 'orders.id', '=', 'order_items.order_id')
            ->pluck('order_items.product_id')
            ->unique();

        $recommended = Product::where('is_available', true)
            ->whereIn('category_id', $orderedCategoryIds)
            ->whereNotIn('id', $orderedProductIds)
            ->orderByDesc('score')
            ->limit($limit)
            ->get();

        // Fill with top products if not enough
        if ($recommended->count() < $limit) {
            $remaining = $limit - $recommended->count();
            $filler = Product::where('is_available', true)
                ->whereNotIn('id', $recommended->pluck('id')->merge($orderedProductIds))
                ->orderByDesc('score')
                ->limit($remaining)
                ->get();
            $recommended = $recommended->merge($filler);
        }

        return $recommended;
    }

    /**
     * Recalculate scores for all products.
     */
    public function recalculateAllScores(): void
    {
        Product::all()->each(function (Product $product) {
            $product->recalculateScore();
        });
    }
}
