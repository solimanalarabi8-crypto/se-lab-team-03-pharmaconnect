<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacy_id')->constrained('pharmacies')->onDelete('cascade');
            $table->foreignId('medicine_id')->constrained('medicines')->onDelete('cascade');
            $table->unsignedInteger('quantity')->default(0);
            $table->decimal('price', 8, 2);
            $table->date('expiry_date')->nullable();
            $table->timestamps();

            // A pharmacy can only have one record per medicine
            $table->unique(['pharmacy_id', 'medicine_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventories');
    }
};
