<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Services\RecommendationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Product::with('category')->where('is_available', true);

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        $products = $query->orderByDesc('score')->paginate(12);

        return response()->json($products);
    }

    public function show(Product $product): JsonResponse
    {
        $product->load(['category', 'reviews.user']);

        return response()->json($product);
    }

    public function recommended(Request $request, RecommendationService $service): JsonResponse
    {
        if ($request->user()) {
            $products = $service->getPersonalized($request->user()->id);
        } else {
            $products = $service->getTopProducts();
        }

        $products->load('category');

        return response()->json($products);
    }
}
