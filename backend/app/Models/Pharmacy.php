<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pharmacy extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'license_number',
        'phone',
        'address',
        'latitude',
        'longitude',
        'is_active',
        'is_verified',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'is_active' => 'boolean',
            'is_verified' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function pharmacyMedicines(): HasMany
    {
        return $this->hasMany(PharmacyMedicine::class);
    }

    public function medicines(): BelongsToMany
    {
        return $this->belongsToMany(Medicine::class, 'pharmacy_medicines')
            ->withPivot(['id', 'available_quantity', 'price', 'status'])
            ->withTimestamps();
    }

    public function reservations(): HasMany
    {
        return $this->hasMany(Reservation::class);
    }
}
