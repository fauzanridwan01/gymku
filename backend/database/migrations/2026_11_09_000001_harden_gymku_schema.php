<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Perbaikan skema: index untuk query dashboard/booking, constraint yang selama ini
 * hanya dijaga di kode, dan riwayat pembayaran tidak ikut terhapus saat user dihapus.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Nama/email unik tanpa membedakan huruf besar-kecil (login boleh memakai nama).
        DB::statement('CREATE UNIQUE INDEX users_name_lower_unique ON users (LOWER(name))');
        DB::statement('CREATE UNIQUE INDEX users_email_lower_unique ON users (LOWER(email))');

        Schema::table('bookings', fn (Blueprint $t) => $t->index('gym_class_id'));
        Schema::table('checkins', fn (Blueprint $t) => $t->index('checked_in_at'));
        Schema::table('transactions', fn (Blueprint $t) => $t->index('paid_at'));
        Schema::table('announcements', fn (Blueprint $t) => $t->index('target_user_id'));
        Schema::table('freezes', fn (Blueprint $t) => $t->index('membership_id'));

        // Satu target per periode per user (aturan yang sudah dipakai aplikasi Flutter).
        Schema::table('targets', fn (Blueprint $t) => $t->unique(['user_id', 'period']));

        // Data keuangan tidak boleh hilang diam-diam: hapus user ditolak jika punya transaksi.
        Schema::table('transactions', function (Blueprint $t) {
            $t->dropForeign(['user_id']);
            $t->foreign('user_id')->references('id')->on('users')->restrictOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $t) {
            $t->dropForeign(['user_id']);
            $t->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });
        Schema::table('targets', fn (Blueprint $t) => $t->dropUnique(['user_id', 'period']));
        Schema::table('freezes', fn (Blueprint $t) => $t->dropIndex(['membership_id']));
        Schema::table('announcements', fn (Blueprint $t) => $t->dropIndex(['target_user_id']));
        Schema::table('transactions', fn (Blueprint $t) => $t->dropIndex(['paid_at']));
        Schema::table('checkins', fn (Blueprint $t) => $t->dropIndex(['checked_in_at']));
        Schema::table('bookings', fn (Blueprint $t) => $t->dropIndex(['gym_class_id']));
        DB::statement('DROP INDEX users_email_lower_unique');
        DB::statement('DROP INDEX users_name_lower_unique');
    }
};
