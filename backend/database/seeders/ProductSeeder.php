<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\Category;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $categories = Category::all()->keyBy('slug');

        $products = [
            // Main Course
            ['category' => 'main-course', 'name' => 'Nasi Goreng Special', 'description' => 'Fried rice with chicken, shrimp, and vegetables, topped with a fried egg and crispy shallots.', 'price' => 35000, 'order_count' => 150, 'avg_rating' => 4.8],
            ['category' => 'main-course', 'name' => 'Ayam Bakar Madu', 'description' => 'Grilled chicken marinated in honey and spices, served with steamed rice and sambal.', 'price' => 42000, 'order_count' => 120, 'avg_rating' => 4.7],
            ['category' => 'main-course', 'name' => 'Mie Goreng Seafood', 'description' => 'Stir-fried noodles with fresh shrimp, squid, and vegetables in savory sauce.', 'price' => 38000, 'order_count' => 95, 'avg_rating' => 4.5],
            ['category' => 'main-course', 'name' => 'Rendang Sapi', 'description' => 'Slow-cooked beef in rich coconut and spice gravy. Served with steamed rice.', 'price' => 55000, 'order_count' => 80, 'avg_rating' => 4.9],

            // Beverages
            ['category' => 'beverages', 'name' => 'Es Teh Manis', 'description' => 'Sweet iced tea made from premium Javanese tea leaves.', 'price' => 8000, 'order_count' => 200, 'avg_rating' => 4.3],
            ['category' => 'beverages', 'name' => 'Jus Alpukat', 'description' => 'Creamy avocado juice blended with chocolate and condensed milk.', 'price' => 18000, 'order_count' => 75, 'avg_rating' => 4.6],
            ['category' => 'beverages', 'name' => 'Kopi Susu Gula Aren', 'description' => 'Espresso with fresh milk and palm sugar syrup.', 'price' => 22000, 'order_count' => 110, 'avg_rating' => 4.8],
            ['category' => 'beverages', 'name' => 'Es Jeruk Segar', 'description' => 'Fresh squeezed orange juice with ice.', 'price' => 12000, 'order_count' => 90, 'avg_rating' => 4.2],

            // Desserts
            ['category' => 'desserts', 'name' => 'Es Cendol', 'description' => 'Traditional dessert with pandan jelly, coconut milk, and palm sugar.', 'price' => 15000, 'order_count' => 60, 'avg_rating' => 4.4],
            ['category' => 'desserts', 'name' => 'Pisang Goreng Keju', 'description' => 'Crispy fried banana topped with melted cheese and chocolate sauce.', 'price' => 18000, 'order_count' => 55, 'avg_rating' => 4.5],
            ['category' => 'desserts', 'name' => 'Puding Mangga', 'description' => 'Silky mango pudding topped with fresh mango cubes and cream.', 'price' => 20000, 'order_count' => 40, 'avg_rating' => 4.6],

            // Snacks
            ['category' => 'snacks', 'name' => 'Tahu Crispy', 'description' => 'Crispy fried tofu bites served with spicy peanut sauce.', 'price' => 12000, 'order_count' => 85, 'avg_rating' => 4.3],
            ['category' => 'snacks', 'name' => 'Lumpia Semarang', 'description' => 'Crispy spring rolls filled with bamboo shoots and chicken.', 'price' => 15000, 'order_count' => 70, 'avg_rating' => 4.4],
            ['category' => 'snacks', 'name' => 'Dimsum Mix', 'description' => 'Assorted steamed dumplings: hakau, siomay, and lumpia udang.', 'price' => 28000, 'order_count' => 65, 'avg_rating' => 4.7],

            // Specials
            ['category' => 'specials', 'name' => 'Wagyu Beef Bowl', 'description' => 'Premium wagyu beef slices on garlic butter rice with teriyaki glaze.', 'price' => 85000, 'order_count' => 30, 'avg_rating' => 4.9],
            ['category' => 'specials', 'name' => 'Lobster Butter Rice', 'description' => 'Whole grilled lobster on fragrant butter rice with lemon herb sauce.', 'price' => 120000, 'order_count' => 15, 'avg_rating' => 5.0],
            ['category' => 'specials', 'name' => 'Sate Lilit Bali', 'description' => 'Balinese-style minced seafood satay with aromatic spices and lemongrass.', 'price' => 45000, 'order_count' => 45, 'avg_rating' => 4.6],
        ];

        foreach ($products as $item) {
            $category = $categories[$item['category']];
            $score = ($item['order_count'] * 0.6) + ($item['avg_rating'] * 0.4);

            Product::create([
                'category_id' => $category->id,
                'name' => $item['name'],
                'description' => $item['description'],
                'price' => $item['price'],
                'is_available' => true,
                'order_count' => $item['order_count'],
                'avg_rating' => $item['avg_rating'],
                'score' => $score,
            ]);
        }
    }
}
