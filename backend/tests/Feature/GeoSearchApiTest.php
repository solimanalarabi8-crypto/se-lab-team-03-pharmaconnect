<?php

namespace Tests\Feature;

use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\PharmacyMedicine;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GeoSearchApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_search_medicines_by_name_and_location(): void
    {
        // 1. إنشاء مستخدم وصيدلية معتمدة
        $user = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::create([
            'user_id' => $user->id,
            'name' => 'صيدلية الاختبار',
            'license_number' => 'TEST-001',
            'phone' => '777000000',
            'address' => 'صنعاء - شارع حدة',
            'latitude' => 15.3268,
            'longitude' => 44.1951,
            'is_active' => true,
            'is_verified' => true,
        ]);

        // 2. إنشاء دواء وإضافته للمخزون
        $medicine = Medicine::create([
            'trade_name' => 'Panadol Extra',
            'scientific_name' => 'Paracetamol',
            'barcode' => '1234567890',
            'dosage_form' => 'Tablets',
            'strength' => '500mg',
        ]);

        PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $medicine->id,
            'available_quantity' => 10,
            'price' => 1200.00,
            'status' => 'available',
        ]);

        // 3. اختبار استدعاء الـ API مع إحداثيات قريبة
        $response = $this->getJson('/api/v1/medicines/search?q=Panadol&lat=15.3300&lng=44.1900');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('count', 1)
            ->assertJsonPath('data.0.medicine.trade_name', 'Panadol Extra')
            ->assertJsonPath('data.0.pharmacy.name', 'صيدلية الاختبار')
            ->assertJsonPath('data.0.available_quantity', 10);
    }
}
