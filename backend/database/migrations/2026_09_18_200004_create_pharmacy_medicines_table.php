<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('pharmacy_medicines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacy_id')->constrained()->cascadeOnDelete();
            $table->foreignId('medicine_id')->constrained()->cascadeOnDelete();
            $table->integer('available_quantity')->default(0);
            $table->decimal('price', 10, 2);
            $table->enum('status', ['available', 'low_stock', 'out_of_stock'])->default('available')->index();
            $table->timestamps();

            // ضمان عدم تكرار نفس الدواء في نفس الصيدلية
            $table->unique(['pharmacy_id', 'medicine_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pharmacy_medicines');
    }
};
