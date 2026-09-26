<?php

namespace App\Services;

use App\Models\PharmacyMedicine;
use App\Models\Reservation;
use App\Models\ReservationItem;
use App\Repositories\Contracts\ReservationRepositoryInterface;
use Exception;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ReservationService
{
    public function __construct(
        protected ReservationRepositoryInterface $reservationRepository
    ) {}

    /**
     * إنشاء حجز مؤقت مع حماية التزامن وأقفال الصفوف (Pessimistic Locking)
     *
     * @throws Exception
     */
    public function createReservation(
        int $userId,
        int $pharmacyMedicineId,
        int $quantity = 1,
        int $ttlMinutes = 30
    ): Reservation {
        return DB::transaction(function () use ($userId, $pharmacyMedicineId, $quantity, $ttlMinutes) {
            // قفل الصف لمنع أي معاملة متزامنة أخرى من حجز نفس الكمية (Concurrency Control)
            $stock = PharmacyMedicine::where('id', $pharmacyMedicineId)
                ->lockForUpdate()
                ->first();

            if (! $stock) {
                throw new Exception('عذراً، الصنف المطلوب غير موجود في مخزون هذه الصيدلية.');
            }

            if ($stock->available_quantity < $quantity) {
                throw new Exception("عذراً، الكمية المتوفرة حالياً ({$stock->available_quantity}) أقل من الكمية المطلوبة.");
            }

            // خصم الكمية مؤقتاً من المخزون
            $stock->decrement('available_quantity', $quantity);

            if ($stock->available_quantity === 0) {
                $stock->update(['status' => 'out_of_stock']);
            } elseif ($stock->available_quantity <= 5) {
                $stock->update(['status' => 'low_stock']);
            }

            // إنشاء سجل الحجز مع مؤقت الـ TTL
            $reservationCode = 'RES-'.strtoupper(Str::random(6));
            $totalAmount = $stock->price * $quantity;

            $reservation = Reservation::create([
                'reservation_code' => $reservationCode,
                'user_id' => $userId,
                'pharmacy_id' => $stock->pharmacy_id,
                'status' => 'pending',
                'total_amount' => $totalAmount,
                'expires_at' => now()->addMinutes($ttlMinutes),
            ]);

            ReservationItem::create([
                'reservation_id' => $reservation->id,
                'pharmacy_medicine_id' => $stock->id,
                'quantity' => $quantity,
                'unit_price' => $stock->price,
            ]);

            return $reservation->load(['pharmacy', 'reservationItems.pharmacyMedicine.medicine']);
        });
    }

    /**
     * تأكيد استلام المريض للدواء من الصيدلية
     *
     * @throws Exception
     */
    public function confirmPickup(int $reservationId, int $pharmacyId = 0): Reservation
    {
        return DB::transaction(function () use ($reservationId, $pharmacyId) {
            $query = Reservation::where('id', $reservationId)
                ->lockForUpdate();

            if ($pharmacyId > 0) {
                $query->where('pharmacy_id', $pharmacyId);
            }

            $reservation = $query->first();

            if (! $reservation) {
                throw new Exception('الحجز غير موجود أو لا يتبع هذه الصيدلية.');
            }

            if ($reservation->status !== 'pending' && $reservation->status !== 'confirmed') {
                throw new Exception('لا يمكن تأكيد هذا الحجز نظراً لأنه بحالة: '.$reservation->status);
            }

            $reservation->update([
                'status' => 'completed',
                'completed_at' => now(),
            ]);

            return $reservation;
        });
    }

    /**
     * إلغاء الحجز يدوياً من المريض أو الصيدلي وإعادة الكمية للمخزون
     *
     * @throws Exception
     */
    public function cancelReservation(int $reservationId, ?int $userId = null): Reservation
    {
        return DB::transaction(function () use ($reservationId, $userId) {
            $query = Reservation::with('reservationItems.pharmacyMedicine')
                ->where('id', $reservationId)
                ->lockForUpdate();

            if ($userId !== null) {
                $query->where('user_id', $userId);
            }

            $reservation = $query->first();

            if (! $reservation) {
                throw new Exception('الحجز غير موجود.');
            }

            if ($reservation->status !== 'pending') {
                throw new Exception('لا يمكن إلغاء الحجز في حالته الحالية.');
            }

            // استعادة الكميات إلى المخزون
            foreach ($reservation->reservationItems as $item) {
                $stock = $item->pharmacyMedicine;
                if ($stock) {
                    $stock->increment('available_quantity', $item->quantity);
                    if ($stock->available_quantity > 0) {
                        $stock->update(['status' => 'available']);
                    }
                }
            }

            $reservation->update(['status' => 'cancelled']);

            return $reservation;
        });
    }

    public function getUserReservations(int $userId): Collection
    {
        return $this->reservationRepository->getUserReservations($userId);
    }

    public function getPharmacyReservations(int $pharmacyId): Collection
    {
        return $this->reservationRepository->getPharmacyReservations($pharmacyId);
    }
}
