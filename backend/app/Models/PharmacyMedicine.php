<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PharmacyMedicine extends Model
{
    use HasFactory;

    protected $table = 'pharmacy_medicines';

    protected $fillable = [
        'pharmacy_id',
        'medicine_id',
        'available_quantity',
        'price',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'available_quantity' => 'integer',
            'price' => 'float',
        ];
    }

    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    public function medicine(): BelongsTo
    {
        return $this->belongsTo(Medicine::class);
    }

    public function reservationItems(): HasMany
    {
        return $this->hasMany(ReservationItem::class);
    }

    public function isAvailable(): bool
    {
        return $this->status === 'available' && $this->available_quantity > 0;
    }
}
