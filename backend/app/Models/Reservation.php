<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Reservation extends Model
{
    use HasFactory;

    protected $fillable = [
        'reservation_code',
        'user_id',
        'pharmacy_id',
        'status',
        'total_amount',
        'expires_at',
        'confirmed_at',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'total_amount' => 'float',
            'expires_at' => 'datetime',
            'confirmed_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    public function reservationItems(): HasMany
    {
        return $this->hasMany(ReservationItem::class);
    }

    public function items(): HasMany
    {
        return $this->reservationItems();
    }

    public function isExpired(): bool
    {
        return $this->status === 'pending' && $this->expires_at->isPast();
    }
}
