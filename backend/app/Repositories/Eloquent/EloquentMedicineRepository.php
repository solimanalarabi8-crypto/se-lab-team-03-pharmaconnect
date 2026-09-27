<?php

namespace App\Repositories\Eloquent;

use App\Models\PharmacyMedicine;
use App\Repositories\Contracts\MedicineRepositoryInterface;
use Illuminate\Support\Collection;

class EloquentMedicineRepository implements MedicineRepositoryInterface
{
    /**
     * {@inheritdoc}
     */
    public function searchNearby(
        ?string $query = null,
        ?float $latitude = null,
        ?float $longitude = null,
        float $radiusKm = 25.0
    ): Collection {
        $stockQuery = PharmacyMedicine::with(['medicine.category', 'pharmacy'])
            ->whereHas('pharmacy', function ($q) {
                $q->where('is_active', true)->where('is_verified', true);
            })
            ->where('available_quantity', '>', 0);

        if (! empty($query)) {
            $stockQuery->whereHas('medicine', function ($q) use ($query) {
                $q->where('trade_name', 'like', "%{$query}%")
                    ->orWhere('scientific_name', 'like', "%{$query}%")
                    ->orWhere('barcode', '=', $query);
            });
        }

        $results = $stockQuery->get();

        // حساب المسافة بدقة لكل نتيجة (Haversine Formula)
        return $results->map(function (PharmacyMedicine $item) use ($latitude, $longitude) {
            $pharmacy = $item->pharmacy;
            $distance = null;

            if ($latitude !== null && $longitude !== null && $pharmacy->latitude && $pharmacy->longitude) {
                $distance = $this->calculateHaversineDistance(
                    $latitude,
                    $longitude,
                    (float) $pharmacy->latitude,
                    (float) $pharmacy->longitude
                );
            }

            $item->distance_km = $distance ? round($distance, 2) : 0.0;

            return $item;
        })
            ->when($latitude !== null && $longitude !== null, function ($collection) use ($radiusKm) {
                // تصفية النتائج ضمن نصف القطر وترتيبها من الأقرب إلى الأبعد
                return $collection->filter(function ($item) use ($radiusKm) {
                    return $item->distance_km <= $radiusKm;
                })->sortBy('distance_km')->values();
            });
    }

    /**
     * {@inheritdoc}
     */
    public function getPharmacyStock(int $pharmacyId): Collection
    {
        return PharmacyMedicine::with(['medicine.category'])
            ->where('pharmacy_id', $pharmacyId)
            ->latest('updated_at')
            ->get();
    }

    /**
     * حساب المسافة بين نقطتين جغرافيتين باستخدام صيغة هافرسين بالكيلومتر
     */
    private function calculateHaversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadiusKm = 6371.0;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadiusKm * $c;
    }
}
