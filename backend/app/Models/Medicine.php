<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Medicine extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'scientific_name',
        'category',
        'description',
        'unit',
        'manufacturer',
    ];

    public function inventories()
    {
        return $this->hasMany(Inventory::class);
    }

    public function pharmacies()
    {
        return $this->belongsToMany(Pharmacy::class, 'inventories')
                    ->withPivot(['quantity', 'price', 'expiry_date'])
                    ->withTimestamps();
    }

    public function savedByUsers()
    {
        return $this->hasMany(SavedMedicine::class);
    }
}
