<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('saved_medicines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('medicine_id')->constrained('medicines')->onDelete('cascade');
            $table->timestamp('saved_at')->useCurrent();
            $table->timestamps();

            // A patient can save a medicine only once
            $table->unique(['patient_id', 'medicine_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('saved_medicines');
    }
};
