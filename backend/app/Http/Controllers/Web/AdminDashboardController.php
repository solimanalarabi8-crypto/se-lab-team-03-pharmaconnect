<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\Reservation;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AdminDashboardController extends Controller
{
    /**
     * التحقق من صلاحية المشرف العام
     */
    private function authorizeAdmin(): void
    {
        if (! auth()->check() || ! auth()->user()->isAdmin()) {
            abort(403, 'عذراً، هذه اللوحة مخصصة للمشرف العام للنظام فقط.');
        }
    }

    /**
     * الصفحة الرئيسية للوحة الإدارة المركزية
     */
    public function dashboard(): View
    {
        $this->authorizeAdmin();

        $stats = [
            'total_pharmacies' => Pharmacy::count(),
            'active_pharmacies' => Pharmacy::where('is_active', true)->count(),
            'total_patients' => User::where('role', 'patient')->count(),
            'total_medicines' => Medicine::count(),
            'total_reservations' => Reservation::count(),
            'pending_reservations' => Reservation::where('status', 'pending')->count(),
            'completed_reservations' => Reservation::where('status', 'completed')->count(),
        ];

        $recentPharmacies = Pharmacy::with('user')->latest()->take(5)->get();
        $recentPatients = User::where('role', 'patient')->latest()->take(5)->get();
        $recentReservations = Reservation::with(['pharmacy', 'user'])->latest()->take(6)->get();

        return view('admin.dashboard', compact('stats', 'recentPharmacies', 'recentPatients', 'recentReservations'));
    }

    /**
     * إدارة الصيدليات المسجلة
     */
    public function pharmacies(): View
    {
        $this->authorizeAdmin();

        $pharmacies = Pharmacy::with(['user', 'medicines'])->latest()->paginate(15);

        return view('admin.pharmacies', compact('pharmacies'));
    }

    /**
     * تفعيل أو تعطيل صيدلية
     */
    public function toggleStatus(int $id): RedirectResponse
    {
        $this->authorizeAdmin();

        $pharmacy = Pharmacy::findOrFail($id);
        $pharmacy->is_active = ! $pharmacy->is_active;
        $pharmacy->save();

        $statusText = $pharmacy->is_active ? 'تم تفعيل' : 'تم تعطيل';

        return back()->with('success', "{$statusText} صيدلية ({$pharmacy->name}) بنجاح.");
    }

    /**
     * توثيق أو إلغاء توثيق صيدلية
     */
    public function toggleVerify(int $id): RedirectResponse
    {
        $this->authorizeAdmin();

        $pharmacy = Pharmacy::findOrFail($id);
        $pharmacy->is_verified = ! $pharmacy->is_verified;
        $pharmacy->save();

        $verifyText = $pharmacy->is_verified ? 'تم توثيق واعتماد' : 'تم إلغاء توثيق';

        return back()->with('success', "{$verifyText} صيدلية ({$pharmacy->name}) بنجاح.");
    }

    /**
     * إدارة المرضى ومستخدمي التطبيق
     */
    public function patients(): View
    {
        $this->authorizeAdmin();

        $patients = User::where('role', 'patient')
            ->withCount('reservations')
            ->latest()
            ->paginate(15);

        return view('admin.patients', compact('patients'));
    }

    /**
     * الفهرس الوطني العام للأدوية
     */
    public function medicines(): View
    {
        $this->authorizeAdmin();

        $medicines = Medicine::with('category')->latest()->paginate(15);
        $categories = Category::all();

        return view('admin.medicines', compact('medicines', 'categories'));
    }

    /**
     * إضافة دواء جديد للفهرس العام
     */
    public function storeMedicine(Request $request): RedirectResponse
    {
        $this->authorizeAdmin();

        $validated = $request->validate([
            'trade_name' => 'required|string|max:255',
            'scientific_name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'barcode' => 'nullable|string|max:50|unique:medicines,barcode',
            'dosage_form' => 'required|string|max:100',
            'strength' => 'required|string|max:100',
            'manufacturer' => 'required|string|max:255',
            'is_prescription_required' => 'nullable|boolean',
        ]);

        $validated['is_prescription_required'] = $request->boolean('is_prescription_required');

        Medicine::create($validated);

        return back()->with('success', "تم إضافة الدواء ({$validated['trade_name']}) إلى الفهرس الوطني بنجاح.");
    }
}
