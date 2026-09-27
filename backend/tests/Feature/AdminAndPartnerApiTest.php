<?php

namespace Tests\Feature;

use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminAndPartnerApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    public function test_admin_can_access_dashboard(): void
    {
        $admin = User::where('role', 'admin')->first();

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertStatus(200);
        $response->assertSee('لوحة التحكم والإدارة المركزية');
        $response->assertSee('إجمالي الصيدليات');
    }

    public function test_non_admin_cannot_access_admin_dashboard(): void
    {
        $patient = User::where('role', 'patient')->first();

        $response = $this->actingAs($patient)->get('/admin/dashboard');

        $response->assertStatus(403);
    }

    public function test_admin_can_toggle_pharmacy_status_and_verification(): void
    {
        $admin = User::where('role', 'admin')->first();
        $pharmacy = Pharmacy::first();

        $initialStatus = $pharmacy->is_active;

        $response = $this->actingAs($admin)->post("/admin/pharmacies/{$pharmacy->id}/toggle-status");
        $response->assertRedirect();

        $pharmacy->refresh();
        $this->assertNotEquals($initialStatus, $pharmacy->is_active);
    }

    public function test_partner_b2b_api_can_sync_inventory(): void
    {
        $pharmacy = Pharmacy::first();
        $medicine = Medicine::first();

        $payload = [
            'pharmacy_id' => $pharmacy->id,
            'items' => [
                [
                    'medicine_id' => $medicine->id,
                    'quantity' => 45,
                    'price' => 1350.0,
                ],
            ],
        ];

        $response = $this->postJson('/api/v1/partner/inventory/sync', $payload);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('updated_count', 1);

        $this->assertDatabaseHas('pharmacy_medicines', [
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $medicine->id,
            'available_quantity' => 45,
            'price' => 1350.0,
            'status' => 'available',
        ]);
    }

    public function test_partner_b2b_api_can_update_single_stock(): void
    {
        $pharmacy = Pharmacy::first();
        $medicine = Medicine::first();

        $payload = [
            'pharmacy_id' => $pharmacy->id,
            'medicine_id' => $medicine->id,
            'available_quantity' => 2,
            'price' => 1200.0,
        ];

        $response = $this->postJson('/api/v1/partner/inventory/update-item', $payload);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.available_quantity', 2)
            ->assertJsonPath('data.status', 'low_stock');
    }
}
