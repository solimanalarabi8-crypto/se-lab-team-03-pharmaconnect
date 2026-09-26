<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOneThrough;

class ReservationItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'reservation_id',
        'pharmacy_medicine_id',
        'quantity',
        'unit_price',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'integer',
            'unit_price' => 'float',
        ];
    }

    public function reservation(): BelongsTo
    {
        return $this->belongsTo(Reservation::class);
    }

    public function pharmacyMedicine(): BelongsTo
    {
        return $this->belongsTo(PharmacyMedicine::class);
    }

    public function medicine(): HasOneThrough
    {
        return $this->hasOneThrough(Medicine::class, PharmacyMedicine::class, 'id', 'id', 'pharmacy_medicine_id', 'medicine_id');
    }
}
