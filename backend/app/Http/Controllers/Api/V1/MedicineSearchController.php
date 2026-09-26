<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\MedicineSearchResource;
use App\Services\GeoSearchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MedicineSearchController extends Controller
{
    public function __construct(
        protected GeoSearchService $geoSearchService
    ) {}

    /**
     * استعلام وبحث لحظي عن الأدوية المتوفرة في الصيدليات القريبة
     */
    public function search(Request $request): JsonResponse
    {
        $request->validate([
            'q' => 'nullable|string|max:150',
            'lat' => 'nullable|numeric|between:-90,90',
            'lng' => 'nullable|numeric|between:-180,180',
            'radius' => 'nullable|numeric|min:1|max:100',
            'sort_by' => 'nullable|string|in:distance,price',
        ]);

        $query = $request->query('q');
        $lat = $request->filled('lat') ? (float) $request->query('lat') : null;
        $lng = $request->filled('lng') ? (float) $request->query('lng') : null;
        $radius = (float) $request->query('radius', 20.0);
        $sortBy = $request->query('sort_by', 'distance');

        $results = $this->geoSearchService->search($query, $lat, $lng, $radius, $sortBy);

        return response()->json([
            'success' => true,
            'message' => $results->isEmpty() ? 'لا توجد صيدليات يتوفر لديها الدواء حالياً في النطاق المحدد' : 'تم العثور على نتائج متطابقة',
            'count' => $results->count(),
            'data' => MedicineSearchResource::collection($results),
        ]);
    }

    /**
     * استرجاع مخزون صيدلية معينة
     */
    public function pharmacyStock(int $id): JsonResponse
    {
        $stock = $this->geoSearchService->getPharmacyStock($id);

        return response()->json([
            'success' => true,
            'count' => $stock->count(),
            'data' => MedicineSearchResource::collection($stock),
        ]);
    }
}
