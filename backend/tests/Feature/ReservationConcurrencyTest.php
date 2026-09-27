<?php

namespace Tests\Feature;

use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\PharmacyMedicine;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReservationConcurrencyTest extends TestCase
{
    use RefreshDatabase;

    public function test_reservation_deducts_stock_and_creates_ttl(): void
    {
        // 1. إعداد مريض وصيدلية ودواء بمخزون 5
        $patient = User::factory()->create(['role' => 'patient']);
        $pharmaUser = User::factory()->create(['role' => 'pharmacy']);

        $pharmacy = Pharmacy::create([
            'user_id' => $pharmaUser->id,
            'name' => 'صيدلية السلام',
            'license_number' => 'PH-002',
            'phone' => '777123123',
            'address' => 'صنعاء',
            'latitude' => 15.35,
            'longitude' => 44.20,
            'is_active' => true,
            'is_verified' => true,
        ]);

        $medicine = Medicine::create([
            'trade_name' => 'Augmentin 1g',
            'scientific_name' => 'Amoxicillin',
        ]);

        $stock = PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $medicine->id,
            'available_quantity' => 5,
            'price' => 4500.00,
            'status' => 'available',
        ]);

        // 2. تسجيل دخول المريض وإرسال طلب حجز لـ 2 عبوات
        Sanctum::actingAs($patient);

        $response = $this->postJson('/api/v1/reservations', [
            'pharmacy_medicine_id' => $stock->id,
            'quantity' => 2,
            'ttl_minutes' => 30,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total_amount', 9000);

        // 3. التحقق من خصم المخزون إلى 3 فورياً
        $this->assertEquals(3, $stock->fresh()->available_quantity);
    }

    public function test_cannot_reserve_more_than_available_stock(): void
    {
        $patient = User::factory()->create(['role' => 'patient']);
        $pharmaUser = User::factory()->create(['role' => 'pharmacy']);

        $pharmacy = Pharmacy::create([
            'user_id' => $pharmaUser->id,
            'name' => 'صيدلية النور',
            'license_number' => 'PH-003',
            'phone' => '777456456',
            'address' => 'صنعاء',
            'is_active' => true,
            'is_verified' => true,
        ]);

        $medicine = Medicine::create([
            'trade_name' => 'Brufen 400',
            'scientific_name' => 'Ibuprofen',
        ]);

        $stock = PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $medicine->id,
            'available_quantity' => 1,
            'price' => 800.00,
            'status' => 'available',
        ]);

        Sanctum::actingAs($patient);

        // محاولة حجز 2 علب بينما المتاح 1 فقط
        $response = $this->postJson('/api/v1/reservations', [
            'pharmacy_medicine_id' => $stock->id,
            'quantity' => 2,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        // يظل المخزون 1 كما هو دون مساس
        $this->assertEquals(1, $stock->fresh()->available_quantity);
    }

    public function test_my_reservations_strictly_isolates_user_data(): void
    {
        $userA = User::factory()->create(['role' => 'patient', 'name' => 'User A']);
        $userB = User::factory()->create(['role' => 'patient', 'name' => 'User B']);
        $pharmaUser = User::factory()->create(['role' => 'pharmacy']);

        $pharmacy = Pharmacy::create([
            'user_id' => $pharmaUser->id,
            'name' => 'صيدلية الأمل',
            'license_number' => 'PH-004',
            'phone' => '777999888',
            'address' => 'صنعاء',
            'is_active' => true,
            'is_verified' => true,
        ]);

        $medicine = Medicine::create([
            'trade_name' => 'Panadol Extra',
            'scientific_name' => 'Paracetamol',
        ]);

        $stock = PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $medicine->id,
            'available_quantity' => 10,
            'price' => 500.00,
            'status' => 'available',
        ]);

        // User A makes a reservation
        Sanctum::actingAs($userA);
        $this->postJson('/api/v1/reservations', [
            'pharmacy_medicine_id' => $stock->id,
            'quantity' => 1,
        ])->assertStatus(201);

        // User A checks reservations: count is 1
        $resA = $this->getJson('/api/v1/reservations/my');
        $resA->assertStatus(200)
            ->assertJsonPath('count', 1);

        // User B (new user) logs in and checks reservations: count must be 0!
        Sanctum::actingAs($userB);
        $resB = $this->getJson('/api/v1/reservations/my');
        $resB->assertStatus(200)
            ->assertJsonPath('count', 0)
            ->assertJsonCount(0, 'data');

        // Unauthenticated guest checks reservations without codes: must receive 0 (not 20 random items!)
        $this->app['auth']->forgetGuards();
        $resGuest = $this->getJson('/api/v1/reservations/my');
        $resGuest->assertStatus(200)
            ->assertJsonPath('count', 0)
            ->assertJsonCount(0, 'data');
    }
}
