<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Pesanan + pembayaran digabung. QRIS disimulasikan (tanpa payment gateway).
        Schema::create('transactions', function (Blueprint $t) {
            $t->id();
            $t->string('code', 20)->unique(); // TRX-0098
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('plan_id')->nullable()->constrained()->nullOnDelete();
            $t->string('plan_name', 50);
            $t->unsignedInteger('plan_days')->default(0);
            $t->string('method', 20)->default('QRIS');
            $t->unsignedInteger('base_price');
            $t->unsignedInteger('discount')->default(0);
            $t->unsignedInteger('amount');
            $t->foreignId('promo_id')->nullable()->constrained()->nullOnDelete();
            $t->string('promo_label', 120)->nullable();
            $t->string('status', 10)->default('pending'); // pending | paid | expired | cancelled
            $t->date('period_start')->nullable();
            $t->date('period_end')->nullable();
            $t->timestampTz('expires_at')->nullable();
            $t->timestampTz('paid_at')->nullable();
            $t->timestamps();
            $t->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
