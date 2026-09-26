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
        Schema::create('medicines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('scientific_name')->index();
            $table->string('trade_name')->index();
            $table->string('barcode')->unique()->nullable();
            $table->string('dosage_form')->nullable(); // Tablet, Syrup, Injection, etc.
            $table->string('strength')->nullable(); // 500mg, 100ml, etc.
            $table->string('manufacturer')->nullable();
            $table->boolean('is_prescription_required')->default(false);
            $table->timestamps();

            $table->index(['scientific_name', 'trade_name']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('medicines');
    }
};
