<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Review;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function store(Request $request, Product $product): JsonResponse
    {
        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:500',
        ]);

        // Check if user already reviewed this product
        $existing = Review::where('user_id', $request->user()->id)
            ->where('product_id', $product->id)
            ->first();

        if ($existing) {
            $existing->update($validated);
            $review = $existing;
        } else {
            $review = Review::create([
                'user_id' => $request->user()->id,
                'product_id' => $product->id,
                ...$validated,
            ]);
        }

        // Recalculate product rating and score
        $product->recalculateScore();

        $review->load('user');

        return response()->json($review, $existing ? 200 : 201);
    }
}
