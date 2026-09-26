<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reservation extends Model
{
    use HasFactory;

    protected $fillable = [
        'patient_id',
        'inventory_id',
        'quantity',
        'status',
        'reserved_at',
        'expires_at',
        'confirmed_at',
        'notes',
    ];

    protected $casts = [
        'reserved_at'  => 'datetime',
        'expires_at'   => 'datetime',
        'confirmed_at' => 'datetime',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function inventory()
    {
        return $this->belongsTo(Inventory::class);
    }

    public function isExpired(): bool
    {
        return now()->isAfter($this->expires_at);
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function isConfirmed(): bool
    {
        return $this->status === 'confirmed';
    }
}
