<?php

namespace App\Providers;

use App\Repositories\Contracts\MedicineRepositoryInterface;
use App\Repositories\Contracts\ReservationRepositoryInterface;
use App\Repositories\Eloquent\EloquentMedicineRepository;
use App\Repositories\Eloquent\EloquentReservationRepository;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(MedicineRepositoryInterface::class, EloquentMedicineRepository::class);
        $this->app->bind(ReservationRepositoryInterface::class, EloquentReservationRepository::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (config('app.env') === 'production' || env('FORCE_HTTPS', false) || request()->header('X-Forwarded-Proto') === 'https') {
            URL::forceScheme('https');
        }
    }
}
