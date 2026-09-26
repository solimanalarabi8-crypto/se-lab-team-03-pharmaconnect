<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pharmacy extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'phone',
        'latitude',
        'longitude',
        'owner_id',
        'is_active',
    ];

    protected $casts = [
        'latitude'  => 'float',
        'longitude' => 'float',
        'is_active' => 'boolean',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function inventory()
    {
        return $this->hasMany(Inventory::class);
    }

    public function medicines()
    {
        return $this->belongsToMany(Medicine::class, 'inventories')
                    ->withPivot(['quantity', 'price', 'expiry_date'])
                    ->withTimestamps();
    }
}
