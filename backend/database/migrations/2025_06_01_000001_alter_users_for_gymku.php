<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $t) {
            $t->string('role', 10)->default('member')->after('password'); // member | admin
            $t->string('member_code', 20)->nullable()->unique()->after('role');
            $t->string('phone', 30)->nullable();
            $t->string('gender', 20)->nullable();
            $t->date('birth_date')->nullable();
            $t->date('joined_at')->nullable();
            $t->boolean('is_blocked')->default(false);
            $t->unsignedInteger('best_streak')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $t) {
            $t->dropColumn(['role', 'member_code', 'phone', 'gender', 'birth_date', 'joined_at', 'is_blocked', 'best_streak']);
        });
    }
};
