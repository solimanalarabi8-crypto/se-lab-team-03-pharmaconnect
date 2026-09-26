<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\MedicineSearchController;
use App\Http\Controllers\Api\V1\PartnerIntegrationApiController;
use App\Http\Controllers\Api\V1\ReservationApiController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| PharmaConnect RESTful API - Version 1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {
    // 1. المسارات العامة (البحث والاستعلام)
    Route::get('/medicines/search', [MedicineSearchController::class, 'search']);
    Route::get('/pharmacies/{id}/stock', [MedicineSearchController::class, 'pharmacyStock']);

    // 2. مصادقة المستخدمين وتطبيق الهاتف
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::post('/reservations', [ReservationApiController::class, 'store']);
    Route::get('/reservations/my', [ReservationApiController::class, 'myReservations']);
    Route::get('/reservations/{code}', [ReservationApiController::class, 'show']);
    Route::post('/reservations/{id}/cancel', [ReservationApiController::class, 'cancel']);

    // 4. واجهات الربط البرمجي لأنظمة الصيدليات المحاسبية ونقاط البيع (Partner B2B Integration API)
    Route::prefix('partner')->group(function () {
        Route::post('/inventory/sync', [PartnerIntegrationApiController::class, 'syncInventory']);
        Route::post('/inventory/update-item', [PartnerIntegrationApiController::class, 'updateItem']);
        Route::get('/reservations', [PartnerIntegrationApiController::class, 'getReservations']);
        Route::post('/reservations/{id}/fulfill', [PartnerIntegrationApiController::class, 'fulfillReservation']);
    });

    // 5. المسارات المحمية بـ Sanctum (الملف الشخصي وتعديله وتسجيل الخروج)
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/profile', [AuthController::class, 'profile']);
        Route::put('/auth/profile', [AuthController::class, 'updateProfile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
    });
    // مسار تعديل احتياطي مباشر
    Route::put('/auth/profile/update', [AuthController::class, 'updateProfile']);
});
