<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        foreach ([
            ['1m', '1 Bulan', 30, 350000, null, false],
            ['3m', '3 Bulan', 90, 900000, null, true],
            ['6m', '6 Bulan', 180, 1700000, null, false],
            ['12m', '1 Tahun', 360, 2999000, 3299000, false],
        ] as [$code, $name, $days, $price, $orig, $pop]) {
            Plan::updateOrCreate(['code' => $code], [
                'name' => $name, 'days' => $days, 'price' => $price,
                'original_price' => $orig, 'is_popular' => $pop, 'is_enabled' => true,
            ]);
        }
    }
}
