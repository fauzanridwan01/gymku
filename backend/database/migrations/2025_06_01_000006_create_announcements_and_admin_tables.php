<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('announcements', function (Blueprint $t) {
            $t->id();
            $t->string('category', 20); // Pengumuman | Kelas | Promo
            $t->string('title', 120);
            $t->text('body');
            // NULL = semua member; terisi = hanya member tersebut
            $t->foreignId('target_user_id')->nullable()->constrained('users')->cascadeOnDelete();
            $t->boolean('is_banner')->default(false);
            $t->date('valid_until')->nullable();
            $t->string('status', 10)->default('draft'); // draft | published | archived
            $t->timestampTz('published_at')->nullable(); // jika di masa depan = terjadwal
            $t->unsignedInteger('views')->default(0);
            $t->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamps();
            $t->index(['status', 'published_at']);
        });

        Schema::create('block_records', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('reason', 255);
            $t->foreignId('blocked_by')->nullable()->constrained('users')->nullOnDelete();
            $t->boolean('active')->default(true);
            $t->string('unblock_note', 255)->nullable();
            $t->timestampTz('unblocked_at')->nullable();
            $t->timestamps();
        });

        Schema::create('activity_logs', function (Blueprint $t) {
            $t->id();
            $t->string('kind', 20); // price, payment, checkin, block, unblock, promo, freeze, info
            $t->string('text', 255);
            $t->string('detail', 500)->default('');
            $t->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $t->timestampTz('created_at')->useCurrent();
            $t->index('created_at');
        });

        // Tempat untuk modul pencocokan wajah (dikerjakan anggota tim lain).
        Schema::create('face_templates', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $t->string('image_path')->nullable();
            $t->jsonb('embedding')->nullable();
            $t->string('algorithm', 50)->nullable();
            $t->timestampTz('enrolled_at')->useCurrent();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('face_templates');
        Schema::dropIfExists('activity_logs');
        Schema::dropIfExists('block_records');
        Schema::dropIfExists('announcements');
    }
};
