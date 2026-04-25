<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;

class CategoryController extends Controller
{
    public function index(): JsonResponse
    {
        $categories = Category::withCount('products')->get();

        return response()->json($categories);
    }

    public function show(Category $category): JsonResponse
    {
        $category->load('products');

        return response()->json($category);
    }
}
