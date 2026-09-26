<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReservationResource;
use App\Models\Reservation;
use App\Models\User;
use App\Services\ReservationService;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;

class ReservationApiController extends Controller
{
    public function __construct(
        protected ReservationService $reservationService
    ) {}

    /**
     * استخراج هوية المستخدم المصادق سواء عبر Sanctum Middleware أو Bearer Token الممرر
     */
    protected function resolveUser(Request $request): ?User
    {
        if ($user = $request->user()) {
            return $user;
        }

        if ($user = auth('sanctum')->user()) {
            return $user;
        }

        if ($bearerToken = $request->bearerToken()) {
            $accessToken = PersonalAccessToken::findToken($bearerToken);
            if ($accessToken && $accessToken->tokenable instanceof User) {
                return $accessToken->tokenable;
            }
        }

        return null;
    }

    /**
     * إنشاء حجز مؤقت للدواء محمي بالتزامن وقفل الصفوف
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'pharmacy_medicine_id' => 'required|exists:pharmacy_medicines,id',
            'quantity' => 'nullable|integer|min:1|max:10',
            'ttl_minutes' => 'nullable|integer|min:10|max:60',
            'patient_name' => 'nullable|string|max:100',
            'patient_phone' => 'nullable|string|max:30',
        ]);

        $user = $this->resolveUser($request);
        if (! $user) {
            $patientName = ! empty($validated['patient_name']) ? trim($validated['patient_name']) : 'مريض زائر';
            $patientPhone = ! empty($validated['patient_phone']) ? trim($validated['patient_phone']) : null;

            if ($patientPhone) {
                $cleanPhone = preg_replace('/[^0-9]/', '', $patientPhone);
                $user = User::where('phone', $patientPhone)
                    ->orWhere('phone', $cleanPhone)
                    ->first();
            }

            if (! $user) {
                $uniqueGuestId = uniqid();
                $email = 'guest_'.$uniqueGuestId.'@pharmaconnect.ye';

                $user = User::create([
                    'name' => $patientName,
                    'phone' => $patientPhone,
                    'email' => $email,
                    'role' => 'patient',
                    'password' => bcrypt(uniqid('guest_pwd_', true)),
                ]);
            }
        }
        $userId = $user->id;
        $pharmacyMedicineId = (int) $validated['pharmacy_medicine_id'];
        $quantity = (int) ($validated['quantity'] ?? 1);
        $ttlMinutes = (int) ($validated['ttl_minutes'] ?? 30);

        try {
            $reservation = $this->reservationService->createReservation(
                $userId,
                $pharmacyMedicineId,
                $quantity,
                $ttlMinutes
            );

            return response()->json([
                'success' => true,
                'message' => 'تم الحجز المؤقت بنجاح. يرجى التوجه للصيدلية قبل انتهاء المهلة الزمنية.',
                'data' => new ReservationResource($reservation),
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * استعراض قائمة حجوزات المريض الحالية والسابقة
     */
    public function myReservations(Request $request): JsonResponse
    {
        // 1. الأولوية المطلقة للمستخدم المصادق (سواء عبر جلسة Sanctum أو Bearer Token)
        $user = $this->resolveUser($request);
        if ($user) {
            $codes = $request->query('codes');
            if ($codes) {
                $codeList = array_filter(array_map('trim', explode(',', $codes)));
                if (! empty($codeList)) {
                    Reservation::whereIn('reservation_code', $codeList)
                        ->where(function ($q) {
                            $q->whereNull('user_id')
                                ->orWhere('user_id', 0)
                                ->orWhereHas('user', function ($uq) {
                                    $uq->where('email', 'like', 'guest_%');
                                });
                        })
                        ->update(['user_id' => $user->id]);
                }
            }

            $reservations = $this->reservationService->getUserReservations($user->id);

            return response()->json([
                'success' => true,
                'count' => $reservations->count(),
                'data' => ReservationResource::collection($reservations),
            ]);
        }

        // 2. إذا كان زائراً ويمتلك رموز حجز محددة أو رقم هاتف
        $codes = $request->query('codes');
        $phone = $request->query('phone');
        $codeList = $codes ? array_filter(array_map('trim', explode(',', $codes))) : [];
        $cleanPhone = $phone ? preg_replace('/[^0-9]/', '', $phone) : null;

        $query = Reservation::with(['pharmacy', 'reservationItems.pharmacyMedicine.medicine']);

        if (! empty($codeList) && ! empty($cleanPhone)) {
            $foundUser = User::where('phone', $phone)->orWhere('phone', $cleanPhone)->first();
            $query->where(function ($q) use ($codeList, $foundUser) {
                $q->whereIn('reservation_code', $codeList);
                if ($foundUser) {
                    $q->orWhere('user_id', $foundUser->id);
                }
            });
        } elseif (! empty($codeList)) {
            $query->whereIn('reservation_code', $codeList);
        } elseif (! empty($cleanPhone)) {
            $foundUser = User::where('phone', $phone)->orWhere('phone', $cleanPhone)->first();
            if ($foundUser) {
                $query->where('user_id', $foundUser->id);
            } else {
                return response()->json([
                    'success' => true,
                    'count' => 0,
                    'data' => [],
                ]);
            }
        } else {
            return response()->json([
                'success' => true,
                'count' => 0,
                'data' => [],
            ]);
        }

        $reservations = $query->latest()->get();

        return response()->json([
            'success' => true,
            'count' => $reservations->count(),
            'data' => ReservationResource::collection($reservations),
        ]);
    }

    /**
     * إلغاء الحجز من قِبل المريض
     */
    public function cancel(int $id, Request $request): JsonResponse
    {
        try {
            $user = $request->user() ?? User::where('role', 'patient')->first();
            $userId = $user ? $user->id : 0;
            $reservation = $this->reservationService->cancelReservation($id, $userId);

            return response()->json([
                'success' => true,
                'message' => 'تم إلغاء الحجز وإعادة الكمية لمخزون الصيدلية.',
                'data' => new ReservationResource($reservation),
            ]);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * استعلام تفصيلي عن حالة حجز معين برقم الحجز أو المعرف
     */
    public function show(string $codeOrId): JsonResponse
    {
        $reservation = Reservation::with(['pharmacy', 'reservationItems.pharmacyMedicine.medicine'])
            ->where('reservation_code', $codeOrId)
            ->orWhere('id', is_numeric($codeOrId) ? (int) $codeOrId : 0)
            ->first();

        if (! $reservation) {
            return response()->json([
                'success' => false,
                'message' => 'الحجز غير موجود.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new ReservationResource($reservation),
        ]);
    }
}
