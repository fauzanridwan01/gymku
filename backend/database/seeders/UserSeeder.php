<?php

namespace Database\Seeders;

use App\Models\BlockRecord;
use App\Models\Freeze;
use App\Models\Membership;
use App\Models\Plan;
use App\Models\Target;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin (login: "admin" / admin123)
        $this->user('admin', 'admin@gymku.id', 'admin123', 'ADMIN-001', 'admin');

        // Akun demo utama
        $naufal = $this->user('Naufal Badu', 'naufal@gmail.com', 'Gymku123', 'GYM-002145', 'member', [
            'phone' => '+62 831-7079-6020', 'gender' => 'Laki-laki', 'birth_date' => '2001-05-14', 'best_streak' => 8,
        ]);
        Membership::updateOrCreate(['user_id' => $naufal->id], [
            'plan_name' => 'Premium', 'starts_on' => today()->subDays(38), 'ends_on' => today()->addDays(142),
            'total_days' => 180, 'freeze_days_used' => 0,
        ]);
        Target::firstOrCreate(['user_id' => $naufal->id, 'name' => 'Latihan rutin pagi'],
            ['period' => 'weekly', 'count' => 4, 'days' => [1, 3, 5, 6], 'reminder' => false]);
        Target::firstOrCreate(['user_id' => $naufal->id, 'name' => 'Target bulanan'],
            ['period' => 'monthly', 'count' => 16, 'days' => [], 'reminder' => false]);
        $plan = Plan::where('code', '6m')->first();
        Transaction::firstOrCreate(['code' => 'TRX-0098'], [
            'user_id' => $naufal->id, 'plan_id' => $plan->id, 'plan_name' => 'Premium 6 Bulan', 'plan_days' => 180,
            'method' => 'QRIS', 'base_price' => 1700000, 'discount' => 0, 'amount' => 1700000,
            'status' => 'paid', 'period_start' => today()->subDays(38), 'period_end' => today()->addDays(142),
            'paid_at' => now()->subDays(38),
        ]);

        // Pengguna baru tanpa paket
        $this->user('Tamu Baru', 'baru@gymku.id', 'Gymku123', 'GYM-002200', 'member');

        // Member dummy untuk daftar admin
        foreach ([
            ['Naufal Hakim', 'GYM-000359'], ['Naufalia Putri', 'GYM-000211'], ['Andi Rahman', 'GYM-000511'],
            ['Naufal Yaw', 'GYM-111111'],
        ] as [$n, $code]) {
            $u = $this->user($n, $this->slug($n) . '@gymku.id', 'Gymku123', $code, 'member');
            $this->membership($u, 30 + crc32($code) % 60);
        }

        foreach ([['Agus Setiawan', 'GYM-001204', 'Meminjamkan akun ke orang lain'],
                  ['Lukman Maulana', 'GYM-000932', 'Pelanggaran aturan gym']] as [$n, $code, $why]) {
            $u = $this->user($n, $this->slug($n) . '@gymku.id', 'Gymku123', $code, 'member', ['is_blocked' => true]);
            $this->membership($u, 60);
            BlockRecord::firstOrCreate(['user_id' => $u->id], ['reason' => $why, 'active' => true]);
        }

        foreach ([['Dewi Sartika', 'GYM-000774'], ['Fajar Hidayat', 'GYM-001102']] as [$n, $code]) {
            $u = $this->user($n, $this->slug($n) . '@gymku.id', 'Gymku123', $code, 'member');
            $m = $this->membership($u, 90);
            Freeze::firstOrCreate(['membership_id' => $m->id], [
                'starts_on' => today()->subDays(3), 'ends_on' => today()->addDays(11),
                'reason' => 'Sakit', 'remaining_at_start' => 87,
            ]);
            $m->update(['freeze_days_used' => 15]);
        }
    }

    private function user(string $name, string $email, string $pw, string $code, string $role, array $extra = []): User
    {
        return User::updateOrCreate(['email' => $email], [
            'name' => $name, 'password' => $pw, 'role' => $role, 'member_code' => $code,
            'joined_at' => today()->subDays(60),
        ] + $extra);
    }

    private function membership(User $u, int $remaining): Membership
    {
        return Membership::updateOrCreate(['user_id' => $u->id], [
            'plan_name' => 'Premium', 'starts_on' => today()->subDays(180 - $remaining),
            'ends_on' => today()->addDays($remaining), 'total_days' => 180,
        ]);
    }

    private function slug(string $s): string
    {
        return str_replace(' ', '.', strtolower($s));
    }
}
