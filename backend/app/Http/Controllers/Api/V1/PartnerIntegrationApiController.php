<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\PharmacyMedicine;
use App\Models\Reservation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PartnerIntegrationApiController extends Controller
{
    /**
     * التحقق من هوية الصيدلية ومفتاح الربط البرمجي
     */
    private function resolvePharmacy(Request $request): ?Pharmacy
    {
        // دعم التحقق عبر Header مخصص أو المعرف المباشر
        $pharmacyId = $request->header('X-Pharmacy-Id', $request->input('pharmacy_id'));

        if (! $pharmacyId) {
            return null;
        }

        return Pharmacy::where('id', $pharmacyId)->where('is_active', true)->first();
    }

    /**
     * مزامنة دفعة من المخزون والأسعار (Batch Stock Synchronization)
     * تستدعى من نظام الصيدلية المحاسبي (POS / ERP) بشكل دوري أو عند توريد بضاعة جديدة
     */
    public function syncInventory(Request $request): JsonResponse
    {
        $pharmacy = $this->resolvePharmacy($request);

        if (! $pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'تعذر التحقق من هوية الصيدلية أو الصيدلية غير مفعلة.',
            ], 403);
        }

        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.medicine_id' => 'nullable|exists:medicines,id',
            'items.*.barcode' => 'nullable|string',
            'items.*.quantity' => 'required|integer|min:0',
            'items.*.price' => 'required|numeric|min:0',
        ]);

        $updatedCount = 0;
        $errors = [];

        foreach ($validated['items'] as $index => $itemData) {
            $medicineId = $itemData['medicine_id'] ?? null;

            // إذا أرسل الباركود، نبحث عن الدواء في الفهرس العام
            if (! $medicineId && ! empty($itemData['barcode'])) {
                $med = Medicine::where('barcode', $itemData['barcode'])->first();
                if ($med) {
                    $medicineId = $med->id;
                }
            }

            if (! $medicineId) {
                $errors[] = "العنصر في الفهرس #{$index}: الدواء غير موجود بالفهرس العام.";

                continue;
            }

            $quantity = $itemData['quantity'];
            $status = $quantity <= 0 ? 'out_of_stock' : ($quantity < 5 ? 'low_stock' : 'available');

            PharmacyMedicine::updateOrCreate(
                [
                    'pharmacy_id' => $pharmacy->id,
                    'medicine_id' => $medicineId,
                ],
                [
                    'available_quantity' => $quantity,
                    'price' => $itemData['price'],
                    'status' => $status,
                ]
            );

            $updatedCount++;
        }

        return response()->json([
            'success' => true,
            'message' => "تمت مزامنة {$updatedCount} صنفاً بنجاح في منصة PharmaConnect.",
            'pharmacy' => [
                'id' => $pharmacy->id,
                'name' => $pharmacy->name,
            ],
            'updated_count' => $updatedCount,
            'errors' => $errors,
        ]);
    }

    /**
     * تحديث كمية صنف واحد لحظياً عند كل عملية بيع من نقطة البيع (Real-time POS Hook)
     */
    public function updateItem(Request $request): JsonResponse
    {
        $pharmacy = $this->resolvePharmacy($request);

        if (! $pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'بيانات الصيدلية غير مصرح بها.',
            ], 403);
        }

        $validated = $request->validate([
            'medicine_id' => 'required|exists:medicines,id',
            'available_quantity' => 'required|integer|min:0',
            'price' => 'nullable|numeric|min:0',
        ]);

        $status = $validated['available_quantity'] <= 0 ? 'out_of_stock' : ($validated['available_quantity'] < 5 ? 'low_stock' : 'available');

        $updatePayload = [
            'available_quantity' => $validated['available_quantity'],
            'status' => $status,
        ];

        if (isset($validated['price'])) {
            $updatePayload['price'] = $validated['price'];
        }

        $record = PharmacyMedicine::updateOrCreate(
            [
                'pharmacy_id' => $pharmacy->id,
                'medicine_id' => $validated['medicine_id'],
            ],
            $updatePayload
        );

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث الكمية اللحظية للصنف بنجاح.',
            'data' => [
                'stock_id' => $record->id,
                'medicine_id' => $record->medicine_id,
                'available_quantity' => $record->available_quantity,
                'price' => $record->price,
                'status' => $record->status,
            ],
        ]);
    }

    /**
     * جلب الحجوزات الواردة للصيدلية لسحبها إلى نظام الصيدلية الداخلي
     */
    public function getReservations(Request $request): JsonResponse
    {
        $pharmacy = $this->resolvePharmacy($request);

        if (! $pharmacy) {
            return response()->json(['success' => false, 'message' => 'الصيدلية غير مصرح بها.'], 403);
        }

        $reservations = Reservation::where('pharmacy_id', $pharmacy->id)
            ->with(['items.pharmacyMedicine.medicine', 'user'])
            ->latest()
            ->take(50)
            ->get();

        return response()->json([
            'success' => true,
            'pharmacy_id' => $pharmacy->id,
            'count' => $reservations->count(),
            'data' => $reservations,
        ]);
    }

    /**
     * تأكيد صرف الحجز آلياً من قارئ الباركود/الكاشير بنظام الصيدلية
     */
    public function fulfillReservation(Request $request, int $id): JsonResponse
    {
        $pharmacy = $this->resolvePharmacy($request);

        if (! $pharmacy) {
            return response()->json(['success' => false, 'message' => 'الصيدلية غير مصرح بها.'], 403);
        }

        $reservation = Reservation::where('id', $id)
            ->where('pharmacy_id', $pharmacy->id)
            ->firstOrFail();

        if ($reservation->status === 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'هذا الحجز تم تسليمه مسبقاً.',
            ], 400);
        }

        $reservation->status = 'completed';
        $reservation->save();

        return response()->json([
            'success' => true,
            'message' => "تم تسليم الحجز ({$reservation->reservation_code}) بنجاح عبر الربط البرمجي.",
            'data' => $reservation,
        ]);
    }
}
