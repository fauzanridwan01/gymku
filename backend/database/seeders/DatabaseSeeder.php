<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            PlanSeeder::class,
            PromoSeeder::class,
            UserSeeder::class,
            ClassSeeder::class,
            AnnouncementSeeder::class,
        ]);
    }
}
