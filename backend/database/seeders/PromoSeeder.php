<?php

namespace Database\Seeders;

use App\Models\Plan;
use App\Models\Promo;
use App\Models\PromoCode;
use Illuminate\Database\Seeder;

class PromoSeeder extends Seeder
{
    public function run(): void
    {
        PromoCode::updateOrCreate(['code' => 'GYMKU20'], ['discount_percent' => 20]);
        PromoCode::updateOrCreate(['code' => 'PROMO10'], ['discount_percent' => 10]);

        $p1 = Promo::updateOrCreate(['name' => 'Perpanjang member, diskon 20%'], [
            'type' => 'percent', 'value' => 20, 'quota' => 100, 'used' => 38,
            'renewal_only' => true, 'starts_on' => today()->subDays(5), 'ends_on' => today()->addDays(25),
        ]);
        $p1->plans()->sync(Plan::whereIn('code', ['3m', '6m', '12m'])->pluck('id'));

        $p2 = Promo::updateOrCreate(['name' => 'Promo Tahun Baru, potongan Rp 100.000'], [
            'type' => 'nominal', 'value' => 100000, 'quota' => 50, 'used' => 0,
            'renewal_only' => false, 'starts_on' => today()->addDays(60), 'ends_on' => today()->addDays(67),
        ]);
        $p2->plans()->sync(Plan::pluck('id'));
    }
}
