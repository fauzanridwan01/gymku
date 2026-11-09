<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $t) {
            $t->id();
            $t->string('code', 10)->unique(); // 1m, 3m, 6m, 12m
            $t->string('name', 50);
            $t->unsignedInteger('days');
            $t->unsignedInteger('price');
            $t->unsignedInteger('original_price')->nullable();
            $t->boolean('is_enabled')->default(true);
            $t->boolean('is_popular')->default(false);
            $t->timestamps();
        });

        Schema::create('promos', function (Blueprint $t) {
            $t->id();
            $t->string('name', 120);
            $t->string('type', 10); // percent | nominal
            $t->unsignedInteger('value');
            $t->unsignedInteger('quota');
            $t->unsignedInteger('used')->default(0);
            $t->boolean('renewal_only')->default(false);
            $t->date('starts_on');
            $t->date('ends_on');
            $t->boolean('is_enabled')->default(true);
            $t->boolean('ended_manually')->default(false);
            $t->timestamps();
        });

        Schema::create('promo_plan', function (Blueprint $t) {
            $t->foreignId('promo_id')->constrained()->cascadeOnDelete();
            $t->foreignId('plan_id')->constrained()->cascadeOnDelete();
            $t->primary(['promo_id', 'plan_id']);
        });

        Schema::create('promo_codes', function (Blueprint $t) {
            $t->id();
            $t->string('code', 30)->unique();
            $t->unsignedTinyInteger('discount_percent');
            $t->boolean('is_enabled')->default(true);
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('promo_codes');
        Schema::dropIfExists('promo_plan');
        Schema::dropIfExists('promos');
        Schema::dropIfExists('plans');
    }
};
