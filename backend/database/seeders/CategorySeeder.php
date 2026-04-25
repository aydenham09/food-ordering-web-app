<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Main Course', 'slug' => 'main-course', 'image' => null],
            ['name' => 'Beverages', 'slug' => 'beverages', 'image' => null],
            ['name' => 'Desserts', 'slug' => 'desserts', 'image' => null],
            ['name' => 'Snacks', 'slug' => 'snacks', 'image' => null],
            ['name' => 'Specials', 'slug' => 'specials', 'image' => null],
        ];

        foreach ($categories as $category) {
            Category::create($category);
        }
    }
}
