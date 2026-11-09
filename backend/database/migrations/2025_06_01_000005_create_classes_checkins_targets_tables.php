<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('gym_classes', function (Blueprint $t) {
            $t->id();
            $t->string('title', 100);
            $t->string('studio', 50);
            $t->string('coach', 80);
            $t->string('category', 20); // Yoga | HIIT | Zumba | Core
            $t->timestampTz('starts_at');
            $t->unsignedInteger('capacity')->default(10);
            $t->timestamps();
            $t->index('starts_at');
        });

        Schema::create('bookings', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('gym_class_id')->constrained('gym_classes')->cascadeOnDelete();
            $t->timestamps();
            $t->unique(['user_id', 'gym_class_id']); // batal booking = hapus baris
        });

        Schema::create('checkins', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->timestampTz('checked_in_at');
            $t->string('area', 50)->default('Lantai Beban');
            $t->string('method', 10)->default('face'); // face | manual
            $t->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamps();
            $t->index(['user_id', 'checked_in_at']);
        });

        Schema::create('targets', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('name', 100);
            $t->string('period', 10); // weekly | monthly
            $t->unsignedInteger('count');
            $t->jsonb('days')->nullable(); // [1..7], 1 = Senin
            $t->boolean('reminder')->default(false);
            $t->time('reminder_time')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('targets');
        Schema::dropIfExists('checkins');
        Schema::dropIfExists('bookings');
        Schema::dropIfExists('gym_classes');
    }
};
