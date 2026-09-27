<?php

namespace App\Services;

use App\Repositories\Contracts\MedicineRepositoryInterface;
use Illuminate\Support\Collection;

class GeoSearchService
{
    public function __construct(
        protected MedicineRepositoryInterface $medicineRepository
    ) {}

    /**
     * تنفيذ البحث الذكي وترتيب النتائج
     */
    public function search(
        ?string $query,
        ?float $latitude = null,
        ?float $longitude = null,
        float $radiusKm = 20.0,
        string $sortBy = 'distance' // 'distance' أو 'price'
    ): Collection {
        $results = $this->medicineRepository->searchNearby($query, $latitude, $longitude, $radiusKm);

        if ($sortBy === 'price') {
            return $results->sortBy('price')->values();
        }

        return $results;
    }

    /**
     * استرجاع مخزون صيدلية معينة
     */
    public function getPharmacyStock(int $pharmacyId): Collection
    {
        return $this->medicineRepository->getPharmacyStock($pharmacyId);
    }
}
