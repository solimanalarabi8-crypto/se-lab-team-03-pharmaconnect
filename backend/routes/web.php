<?php

use App\Http\Controllers\Web\AdminDashboardController;
use App\Http\Controllers\Web\PharmacyInventoryController;
use App\Http\Controllers\Web\WebAuthController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| PharmaConnect Web Portal Routes (Pharmacy & Central Admin)
|--------------------------------------------------------------------------
*/

// توجيه الصفحة الرئيسية إلى تسجيل الدخول أو المخزون
Route::get('/', function () {
    return redirect()->route('login');
});

// مسارات المصادقة للويب
Route::get('/login', [WebAuthController::class, 'showLogin'])->name('login');
Route::post('/login', [WebAuthController::class, 'login'])->name('login.post');
Route::match(['get', 'post'], '/logout', [WebAuthController::class, 'logout'])->name('logout');

// مسارات بوابة الصيدلية (محمية بالجلسات)
Route::middleware('auth')->prefix('pharmacy')->name('pharmacy.')->group(function () {
    Route::get('/inventory', [PharmacyInventoryController::class, 'index'])->name('inventory');
    Route::post('/inventory/add', [PharmacyInventoryController::class, 'addMedicine'])->name('inventory.add');
    Route::post('/inventory/{id}/update', [PharmacyInventoryController::class, 'updateStock'])->name('inventory.update');

    Route::get('/reservations', [PharmacyInventoryController::class, 'reservations'])->name('reservations');
    Route::post('/reservations/{id}/confirm', [PharmacyInventoryController::class, 'confirmPickup'])->name('reservations.confirm');
});

// مسارات لوحة الإدارة المركزية للنظام (Super Admin Dashboard)
Route::middleware('auth')->prefix('admin')->name('admin.')->group(function () {
    Route::get('/dashboard', [AdminDashboardController::class, 'dashboard'])->name('dashboard');
    Route::get('/pharmacies', [AdminDashboardController::class, 'pharmacies'])->name('pharmacies');
    Route::post('/pharmacies/{id}/toggle-status', [AdminDashboardController::class, 'toggleStatus'])->name('pharmacies.toggle-status');
    Route::post('/pharmacies/{id}/toggle-verify', [AdminDashboardController::class, 'toggleVerify'])->name('pharmacies.toggle-verify');
    Route::get('/patients', [AdminDashboardController::class, 'patients'])->name('patients');
    Route::get('/medicines', [AdminDashboardController::class, 'medicines'])->name('medicines');
    Route::post('/medicines', [AdminDashboardController::class, 'storeMedicine'])->name('medicines.store');
});
