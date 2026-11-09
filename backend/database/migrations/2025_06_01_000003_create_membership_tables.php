<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Satu keanggotaan per user (diperpanjang di baris yang sama).
        Schema::create('memberships', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $t->string('plan_name', 50);
            $t->date('starts_on');
            $t->date('ends_on');
            $t->unsignedInteger('total_days');
            $t->unsignedInteger('freeze_days_used')->default(0);
            $t->timestamps();
        });

        Schema::create('freezes', function (Blueprint $t) {
            $t->id();
            $t->foreignId('membership_id')->constrained()->cascadeOnDelete();
            $t->date('starts_on');
            $t->date('ends_on'); // inklusif
            $t->string('reason', 255)->default('');
            $t->unsignedInteger('remaining_at_start');
            $t->timestamps();
        });

        Schema::create('freeze_requests', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('type', 10); // freeze | unfreeze
            $t->string('reason', 255)->default('');
            $t->date('since');
            $t->unsignedInteger('days')->default(0);
            $t->string('status', 10)->default('pending'); // pending | approved | rejected
            $t->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestampTz('decided_at')->nullable();
            $t->string('decision_note', 255)->nullable();
            $t->timestamps();
            $t->index(['status', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('freeze_requests');
        Schema::dropIfExists('freezes');
        Schema::dropIfExists('memberships');
    }
};
