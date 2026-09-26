<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    // Relations
    public function pharmacy()
    {
        return $this->hasOne(Pharmacy::class, 'owner_id');
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class, 'patient_id');
    }

    public function savedMedicines()
    {
        return $this->hasMany(SavedMedicine::class, 'patient_id');
    }

    // Helpers
    public function isPharmacist(): bool
    {
        return $this->role === 'pharmacist';
    }

    public function isPatient(): bool
    {
        return $this->role === 'patient';
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }
}
