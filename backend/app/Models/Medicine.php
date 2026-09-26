<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Medicine extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'scientific_name',
        'trade_name',
        'barcode',
        'dosage_form',
        'strength',
        'manufacturer',
        'is_prescription_required',
    ];

    protected function casts(): array
    {
        return [
            'is_prescription_required' => 'boolean',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function pharmacyMedicines(): HasMany
    {
        return $this->hasMany(PharmacyMedicine::class);
    }

    public function pharmacies(): BelongsToMany
    {
        return $this->belongsToMany(Pharmacy::class, 'pharmacy_medicines')
            ->withPivot(['id', 'available_quantity', 'price', 'status'])
            ->withTimestamps();
    }
}
