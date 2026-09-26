<?php

namespace App\Repositories\Contracts;

use App\Models\Reservation;
use Illuminate\Support\Collection;

interface ReservationRepositoryInterface
{
    public function findByCode(string $code): ?Reservation;

    public function getUserReservations(int $userId): Collection;

    public function getPharmacyReservations(int $pharmacyId): Collection;

    public function expirePendingReservations(): int;
}
