<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'role',
        'password',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * الصيدلية التابعة للمستخدم (في حال كان صيدلياً)
     */
    public function pharmacy(): HasOne
    {
        return $this->hasOne(Pharmacy::class);
    }

    /**
     * حجوزات المستخدم (في حال كان مريضاً)
     */
    public function reservations(): HasMany
    {
        return $this->hasMany(Reservation::class);
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isPharmacy(): bool
    {
        return $this->role === 'pharmacy';
    }

    public function isPatient(): bool
    {
        return $this->role === 'patient';
    }
}
