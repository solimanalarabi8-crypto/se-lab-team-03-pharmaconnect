<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\PharmacyMedicine;
use App\Models\Reservation;
use App\Services\ReservationService;
use Exception;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class PharmacyInventoryController extends Controller
{
    public function __construct(
        protected ReservationService $reservationService
    ) {}

    /**
     * استعراض لوحة التحكم والمخزون الحالي للصيدلية
     */
    public function index(Request $request): View
    {
        $pharmacy = $this->getCurrentPharmacy();

        $stockQuery = PharmacyMedicine::with(['medicine.category'])
            ->where('pharmacy_id', $pharmacy->id);

        if ($request->filled('q')) {
            $q = $request->query('q');
            $stockQuery->whereHas('medicine', function ($query) use ($q) {
                $query->where('trade_name', 'like', "%{$q}%")
                    ->orWhere('scientific_name', 'like', "%{$q}%")
                    ->orWhere('barcode', '=', $q);
            });
        }

        $stock = $stockQuery->latest('updated_at')->paginate(15);

        // أصناف من الفهرس العام غير مضافة في مخزون هذه الصيدلية
        $availableCatalog = Medicine::whereDoesntHave('pharmacyMedicines', function ($q) use ($pharmacy) {
            $q->where('pharmacy_id', $pharmacy->id);
        })->get();

        // إحصائيات سريعة للوحة
        $stats = [
            'total_items' => PharmacyMedicine::where('pharmacy_id', $pharmacy->id)->count(),
            'available_count' => PharmacyMedicine::where('pharmacy_id', $pharmacy->id)->where('status', 'available')->count(),
            'low_stock_count' => PharmacyMedicine::where('pharmacy_id', $pharmacy->id)->where('status', 'low_stock')->count(),
            'pending_reservations' => $pharmacy->reservations()->where('status', 'pending')->where('expires_at', '>', now())->count(),
        ];

        return view('pharmacy.inventory', compact('pharmacy', 'stock', 'availableCatalog', 'stats'));
    }

    /**
     * إضافة صنف دواء من الفهرس العام إلى مخزون الصيدلية
     */
    public function addMedicine(Request $request): RedirectResponse
    {
        $pharmacy = $this->getCurrentPharmacy();

        $validated = $request->validate([
            'medicine_id' => 'required|exists:medicines,id',
            'available_quantity' => 'required|integer|min:1',
            'price' => 'required|numeric|min:0',
        ]);

        $status = $validated['available_quantity'] <= 5 ? 'low_stock' : 'available';

        PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $validated['medicine_id'],
            'available_quantity' => $validated['available_quantity'],
            'price' => $validated['price'],
            'status' => $status,
        ]);

        return back()->with('success', 'تمت إضافة الدواء إلى مخزون الصيدلية بنجاح.');
    }

    /**
     * تحديث الكمية والسعر لصنف في المخزون
     */
    public function updateStock(Request $request, int $id): RedirectResponse
    {
        $pharmacy = $this->getCurrentPharmacy();

        $stock = PharmacyMedicine::where('id', $id)
            ->where('pharmacy_id', $pharmacy->id)
            ->firstOrFail();

        $validated = $request->validate([
            'available_quantity' => 'required|integer|min:0',
            'price' => 'required|numeric|min:0',
            'status' => 'required|in:available,low_stock,out_of_stock',
        ]);

        // تحديث آلي للحالة إذا أصبحت الكمية صفر
        if ($validated['available_quantity'] === 0) {
            $validated['status'] = 'out_of_stock';
        }

        $stock->update($validated);

        return back()->with('success', 'تم تحديث بيانات المخزون بنجاح.');
    }

    /**
     * استعراض طلبات الحجز اللحظية الواردة للصيدلية أو لكافة الصيدليات للمشرف
     */
    public function reservations(Request $request): View
    {
        $user = Auth::user();
        $allPharmacies = Pharmacy::all();

        $isSuperAdmin = $user->isAdmin();

        // إتاحة تصفية الحجوزات أو عرض الكل للصيدليات والمشرف
        $defaultId = $user->pharmacy ? (string) $user->pharmacy->id : 'all';
        $selectedPharmacyId = (string) $request->query('pharmacy_id', session('active_reservations_pharmacy_id', $defaultId));
        session(['active_reservations_pharmacy_id' => $selectedPharmacyId]);

        if ($selectedPharmacyId === 'all' || empty($selectedPharmacyId)) {
            $pharmacy = (object) ['name' => 'كافة الصيدليات المشتركة', 'id' => 0];
            $reservations = Reservation::with(['user', 'pharmacy', 'reservationItems.pharmacyMedicine.medicine'])
                ->latest()
                ->get();
        } else {
            $pharmacy = Pharmacy::find((int) $selectedPharmacyId) ?? ($user->pharmacy ?? Pharmacy::firstOrFail());
            $reservations = $this->reservationService->getPharmacyReservations($pharmacy->id);
        }

        return view('pharmacy.reservations', compact('pharmacy', 'reservations', 'allPharmacies', 'selectedPharmacyId', 'isSuperAdmin'));
    }

    /**
     * تأكيد استلام المريض للدواء وإنهاء الحجز
     */
    public function confirmPickup(int $id): RedirectResponse
    {
        $user = Auth::user();
        $pharmacyId = $user->pharmacy ? $user->pharmacy->id : 0;

        try {
            $this->reservationService->confirmPickup($id, $pharmacyId);

            return back()->with('success', 'تم تأكيد تسليم الدواء للمريض بنجاح.');
        } catch (Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }

    /**
     * الحصول على كيان الصيدلية للمستخدم الحالي
     */
    private function getCurrentPharmacy(): Pharmacy
    {
        $user = Auth::user();
        if ($user->pharmacy) {
            return $user->pharmacy;
        }

        // في حال كان مشرف عام، نرجع أول صيدلية كنموذج
        return Pharmacy::firstOrFail();
    }
}
