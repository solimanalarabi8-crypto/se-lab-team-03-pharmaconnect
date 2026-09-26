<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Medicine;
use App\Models\Pharmacy;
use App\Models\PharmacyMedicine;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. إنشاء المشرف العام (Super Admin)
        User::create([
            'name' => 'مشرف النظام المركزي',
            'email' => 'admin@pharmaconnect.ye',
            'phone' => '+967770000001',
            'role' => 'admin',
            'password' => Hash::make('password123'),
        ]);

        // 2. إنشاء مستخدمين صيدليات (Pharmacists)
        $pharmaUser1 = User::create([
            'name' => 'د. أحمد الصيدلي (صيدلية الشفاء)',
            'email' => 'shifa@pharmaconnect.ye',
            'phone' => '+967771111111',
            'role' => 'pharmacy',
            'password' => Hash::make('password123'),
        ]);

        $pharmaUser2 = User::create([
            'name' => 'د. سارة الصيدلانية (صيدلية الأمل)',
            'email' => 'amal@pharmaconnect.ye',
            'phone' => '+967772222222',
            'role' => 'pharmacy',
            'password' => Hash::make('password123'),
        ]);

        // 3. إنشاء مريض تجريبي (Patient)
        User::create([
            'name' => 'خالد علي (مريض)',
            'email' => 'patient@pharmaconnect.ye',
            'phone' => '+967773333333',
            'role' => 'patient',
            'password' => Hash::make('password123'),
        ]);

        // 4. إنشاء كيانات الصيدليات بمواقع جغرافية حقيقية (صنعاء - شارع حدة والستين)
        $pharmacy1 = Pharmacy::create([
            'user_id' => $pharmaUser1->id,
            'name' => 'صيدلية الشفاء المركزية',
            'license_number' => 'PHARM-YE-2024-001',
            'phone' => '+967771111111',
            'address' => 'شارع حدة - أمام برج نماء - صنعاء',
            'latitude' => 15.32685000,
            'longitude' => 44.19512000,
            'is_active' => true,
            'is_verified' => true,
        ]);

        $pharmacy2 = Pharmacy::create([
            'user_id' => $pharmaUser2->id,
            'name' => 'صيدلية الأمل الحديثة',
            'license_number' => 'PHARM-YE-2024-002',
            'phone' => '+967772222222',
            'address' => 'شارع الستين الغربي - جولة مذبح - صنعاء',
            'latitude' => 15.36214000,
            'longitude' => 44.17895000,
            'is_active' => true,
            'is_verified' => true,
        ]);

        // 5. إنشاء تصنيفات الأدوية (Categories)
        $catAnalgesics = Category::create([
            'name' => 'مسكنات ومضادات الالتهاب',
            'slug' => 'analgesics-anti-inflammatory',
            'description' => 'أدوية تخفيف الآلام وخافضات الحرارة',
        ]);

        $catAntibiotics = Category::create([
            'name' => 'المضادات الحيوية',
            'slug' => 'antibiotics',
            'description' => 'أدوية مكافحة العدوى البكتيرية',
        ]);

        $catChronic = Category::create([
            'name' => 'أدوية الأمراض المزمنة والضغط والقلب',
            'slug' => 'cardiovascular-hypertension',
            'description' => 'أدوية علاج ضغط الدم والأوعية الدموية',
        ]);

        // 6. إنشاء الفهرس العام للأدوية (Medicines)
        $med1 = Medicine::create([
            'category_id' => $catAnalgesics->id,
            'scientific_name' => 'Paracetamol',
            'trade_name' => 'Panadol Extra',
            'barcode' => '6281001001234',
            'dosage_form' => 'أقراص (Tablets)',
            'strength' => '500mg + 65mg Caffeine',
            'manufacturer' => 'GSK',
            'is_prescription_required' => false,
        ]);

        $med2 = Medicine::create([
            'category_id' => $catAntibiotics->id,
            'scientific_name' => 'Amoxicillin + Clavulanic Acid',
            'trade_name' => 'Augmentin',
            'barcode' => '6281002005678',
            'dosage_form' => 'أقراص (Tablets)',
            'strength' => '1g (1000mg)',
            'manufacturer' => 'GSK',
            'is_prescription_required' => true,
        ]);

        $med3 = Medicine::create([
            'category_id' => $catChronic->id,
            'scientific_name' => 'Amlodipine',
            'trade_name' => 'Norvasc',
            'barcode' => '6281003009999',
            'dosage_form' => 'أقراص (Tablets)',
            'strength' => '5mg',
            'manufacturer' => 'Pfizer',
            'is_prescription_required' => true,
        ]);

        $med4 = Medicine::create([
            'category_id' => $catAnalgesics->id,
            'scientific_name' => 'Ibuprofen',
            'trade_name' => 'Brufen',
            'barcode' => '6281004001111',
            'dosage_form' => 'أقراص (Tablets)',
            'strength' => '400mg',
            'manufacturer' => 'Abbott',
            'is_prescription_required' => false,
        ]);

        // 7. ربط المخزون بالصيدليات (Pharmacy Stock)
        // صيدلية الشفاء: يتوفر لديها Panadol و Augmentin
        PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy1->id,
            'medicine_id' => $med1->id,
            'available_quantity' => 15,
            'price' => 1200.00,
            'status' => 'available',
        ]);

        PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy1->id,
            'medicine_id' => $med2->id,
            'available_quantity' => 4,
            'price' => 4500.00,
            'status' => 'low_stock',
        ]);

        // صيدلية الأمل: يتوفر لديها Panadol و Norvasc و Brufen
        PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy2->id,
            'medicine_id' => $med1->id,
            'available_quantity' => 20,
            'price' => 1100.00,
            'status' => 'available',
        ]);

        PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy2->id,
            'medicine_id' => $med3->id,
            'available_quantity' => 8,
            'price' => 3800.00,
            'status' => 'available',
        ]);

        PharmacyMedicine::create([
            'pharmacy_id' => $pharmacy2->id,
            'medicine_id' => $med4->id,
            'available_quantity' => 12,
            'price' => 950.00,
            'status' => 'available',
        ]);
    }
}
