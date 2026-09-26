<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Inventory extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacy_id',
        'medicine_id',
        'quantity',
        'price',
        'expiry_date',
    ];

    protected $casts = [
        'price'       => 'float',
        'expiry_date' => 'date',
    ];

    public function pharmacy()
    {
        return $this->belongsTo(Pharmacy::class);
    }

    public function medicine()
    {
        return $this->belongsTo(Medicine::class);
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class);
    }

    public function hasStock(int $quantity = 1): bool
    {
        return $this->quantity >= $quantity;
    }
}
