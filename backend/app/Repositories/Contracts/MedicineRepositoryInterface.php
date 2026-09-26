<?php

namespace App\Repositories\Contracts;

use Illuminate\Support\Collection;

interface MedicineRepositoryInterface
{
    /**
     * البحث عن الأدوية المتوفرة في الصيدليات القريبة مع حساب المسافة
     *
     * @param  string|null  $query  اسم الدواء أو الباركود
     * @param  float|null  $latitude  خط العرض لموقع المريض
     * @param  float|null  $longitude  خط الطول لموقع المريض
     * @param  float  $radiusKm  نصف قطر البحث بالكيلومتر
     */
    public function searchNearby(
        ?string $query = null,
        ?float $latitude = null,
        ?float $longitude = null,
        float $radiusKm = 15.0
    ): Collection;

    /**
     * استرجاع مخزون صيدلية معينة بالكامل
     */
    public function getPharmacyStock(int $pharmacyId): Collection;
}
