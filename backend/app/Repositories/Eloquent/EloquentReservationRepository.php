<?php

namespace App\Repositories\Eloquent;

use App\Models\Reservation;
use App\Repositories\Contracts\ReservationRepositoryInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class EloquentReservationRepository implements ReservationRepositoryInterface
{
    public function findByCode(string $code): ?Reservation
    {
        return Reservation::with(['pharmacy', 'reservationItems.pharmacyMedicine.medicine'])
            ->where('reservation_code', $code)
            ->first();
    }

    public function getUserReservations(int $userId): Collection
    {
        return Reservation::with(['pharmacy', 'reservationItems.pharmacyMedicine.medicine'])
            ->where('user_id', $userId)
            ->latest()
            ->get();
    }

    public function getPharmacyReservations(int $pharmacyId): Collection
    {
        return Reservation::with(['user', 'reservationItems.pharmacyMedicine.medicine'])
            ->where('pharmacy_id', $pharmacyId)
            ->latest()
            ->get();
    }

    /**
     * إلغاء الحجوزات المعلقة التي تجاوزت مدة صلاحيتها (TTL) وإرجاع الكمية للمخزون
     */
    public function expirePendingReservations(): int
    {
        return DB::transaction(function () {
            $expiredReservations = Reservation::with('reservationItems.pharmacyMedicine')
                ->where('status', 'pending')
                ->where('expires_at', '<=', now())
                ->lockForUpdate()
                ->get();

            $count = 0;
            foreach ($expiredReservations as $reservation) {
                // استرجاع الكمية إلى المخزون
                foreach ($reservation->reservationItems as $item) {
                    $stock = $item->pharmacyMedicine;
                    if ($stock) {
                        $stock->increment('available_quantity', $item->quantity);
                        if ($stock->available_quantity > 0 && $stock->status === 'out_of_stock') {
                            $stock->update(['status' => 'available']);
                        }
                    }
                }

                $reservation->update(['status' => 'expired']);
                $count++;
            }

            return $count;
        });
    }
}
