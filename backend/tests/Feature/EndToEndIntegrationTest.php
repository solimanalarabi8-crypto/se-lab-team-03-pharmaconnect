<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\PharmacyMedicine;
use App\Models\Reservation;
use App\Models\User;
use App\Repositories\Contracts\ReservationRepositoryInterface;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EndToEndIntegrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_full_pharmaconnect_end_to_end_lifecycle(): void
    {
        // 1. Setup Master Data
        $category = Category::create([
            'name' => 'مسكنات ومضادات الالتهاب',
            'slug' => 'analgesics',
        ]);

        $medicine = Medicine::create([
            'category_id' => $category->id,
            'trade_name' => 'Panadol Extra',
            'scientific_name' => 'Paracetamol + Caffeine',
            'dosage_form' => 'Tablets',
            'strength' => '500mg',
            'manufacturer' => 'GSK',
        ]);

        $userPharmacist = User::create([
            'name' => 'د. محمد الشفاء',
            'email' => 'shifa@pharmaconnect.local',
            'phone' => '+967771111111',
            'password' => bcrypt('password123'),
            'role' => 'pharmacy',
        ]);

        $pharmacy = Pharmacy::create([
            'user_id' => $userPharmacist->id,
            'name' => 'صيدلية الشفاء المركزية',
            'license_number' => 'PH-SANAA-1001',
            'phone' => '+967771111111',
            'address' => 'شارع حدة - صنعاء',
            'latitude' => 15.3268,
            'longitude' => 44.1951,
            'is_active' => true,
            'is_verified' => true,
        ]);

        $stock = PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $medicine->id,
            'available_quantity' => 10,
            'price' => 1200.00,
            'status' => 'available',
        ]);

        // 2. Web Portal Action: Pharmacist logs in and updates stock & price
        $this->actingAs($userPharmacist);

        $updateResponse = $this->from('/pharmacy/inventory')->post("/pharmacy/inventory/{$stock->id}/update", [
            'available_quantity' => 25,
            'price' => 1350.00,
            'status' => 'available',
        ]);

        $updateResponse->assertRedirect('/pharmacy/inventory');
        $this->assertDatabaseHas('pharmacy_medicines', [
            'id' => $stock->id,
            'available_quantity' => 25,
            'price' => 1350.00,
        ]);

        // 3. Mobile Patient Action: Real-time Geo-Search
        $searchResponse = $this->getJson('/api/v1/medicines/search?q=Panadol&lat=15.3268&lng=44.1951&radius=15');
        $searchResponse->assertStatus(200)
            ->assertJsonPath('data.0.stock_id', $stock->id)
            ->assertJsonPath('data.0.available_quantity', 25)
            ->assertJsonPath('data.0.price', 1350)
            ->assertJsonPath('data.0.medicine.trade_name', 'Panadol Extra');

        // 4. Mobile Patient Action: Create Reservation with 30-min TTL
        $patientUser = User::create([
            'name' => 'المريض أحمد',
            'email' => 'ahmed@patient.local',
            'phone' => '+967772345678',
            'password' => bcrypt('patient123'),
            'role' => 'patient',
        ]);

        $reserveResponse = $this->actingAs($patientUser, 'sanctum')->postJson('/api/v1/reservations', [
            'pharmacy_medicine_id' => $stock->id,
            'quantity' => 3,
            'ttl_minutes' => 30,
        ]);

        $reserveResponse->assertStatus(201)
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.total_amount', 4050) // 3 * 1350
            ->assertJsonPath('data.items.0.quantity', 3);

        $reservationCode = $reserveResponse->json('data.reservation_code');

        // Verify stock deducted in database atomically (25 - 3 = 22)
        $this->assertDatabaseHas('pharmacy_medicines', [
            'id' => $stock->id,
            'available_quantity' => 22,
        ]);

        // 5. Web Portal Action: Pharmacist views reservations and confirms order pickup
        $this->actingAs($userPharmacist);

        $ordersPage = $this->get('/pharmacy/reservations');
        $ordersPage->assertStatus(200);
        $ordersPage->assertSee($reservationCode);

        $reservationRecord = Reservation::where('reservation_code', $reservationCode)->first();

        $confirmResponse = $this->from('/pharmacy/reservations')->post("/pharmacy/reservations/{$reservationRecord->id}/confirm");
        $confirmResponse->assertRedirect('/pharmacy/reservations');

        $this->assertDatabaseHas('reservations', [
            'id' => $reservationRecord->id,
            'status' => 'completed',
        ]);

        // 6. Expiration & Stock Restoration Cycle (Simulating TTL Expiry on another order)
        $expiredReservation = Reservation::create([
            'user_id' => $patientUser->id,
            'pharmacy_id' => $pharmacy->id,
            'reservation_code' => 'RES-EXPIRED-TEST',
            'status' => 'pending',
            'total_amount' => 1350.00,
            'expires_at' => now()->subMinutes(5), // Expired 5 mins ago
        ]);

        $expiredReservation->items()->create([
            'pharmacy_medicine_id' => $stock->id,
            'quantity' => 2,
            'unit_price' => 1350.00,
            'subtotal' => 2700.00,
        ]);

        // Deduct temporarily to simulate active holding
        $stock->decrement('available_quantity', 2);
        $this->assertEquals(20, $stock->fresh()->available_quantity);

        // Run auto-expiration cleanup
        $repo = app(ReservationRepositoryInterface::class);
        $expiredCount = $repo->expirePendingReservations();

        $this->assertGreaterThanOrEqual(1, $expiredCount);
        $this->assertDatabaseHas('reservations', [
            'id' => $expiredReservation->id,
            'status' => 'expired',
        ]);

        // Verify the 2 units are restored back to available stock (20 + 2 = 22)
        $this->assertEquals(22, $stock->fresh()->available_quantity);
    }
}
