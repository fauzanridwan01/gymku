<?php

namespace Database\Seeders;

use App\Models\Announcement;
use App\Models\User;
use Illuminate\Database\Seeder;

class AnnouncementSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'admin')->first();
        $rows = [
            ['Pengumuman', 'Jadwal Operasional Gym saat Libur Nasional', 'Gym tetap buka pukul 08.00–16.00 pada hari libur nasional.', false, 1000, 7],
            ['Kelas', 'Kelas baru: Zumba Night setiap malam', 'Zumba Night hadir setiap malam pukul 20.00 di Studio A bersama Coach Sari.', false, 640, 3],
            ['Promo', 'Perpanjang Member, Diskon 20%', 'Gunakan kode GYMKU20 saat pembayaran', true, 2300, 1],
        ];
        foreach ($rows as [$cat, $title, $body, $banner, $views, $daysAgo]) {
            Announcement::updateOrCreate(['title' => $title], [
                'category' => $cat, 'body' => $body, 'is_banner' => $banner, 'views' => $views,
                'status' => 'published', 'published_at' => now()->subDays($daysAgo), 'created_by' => $admin?->id,
            ]);
        }
    }
}
