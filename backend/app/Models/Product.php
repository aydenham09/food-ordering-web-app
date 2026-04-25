<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id', 'name', 'description', 'price', 'image',
        'is_available', 'order_count', 'avg_rating', 'score',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'avg_rating' => 'decimal:2',
            'score' => 'decimal:2',
            'is_available' => 'boolean',
        ];
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function recalculateScore(): void
    {
        $this->avg_rating = $this->reviews()->avg('rating') ?? 0;
        $this->score = ($this->order_count * 0.6) + ($this->avg_rating * 0.4);
        $this->save();
    }
}
