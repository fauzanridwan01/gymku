<?php

namespace App\Services;

use App\Models\Plan;
use App\Models\Promo;
use App\Models\PromoCode;
use Illuminate\Validation\ValidationException;

/** Semua perhitungan harga/diskon dilakukan di server (bukan di aplikasi). */
class Pricing
{
    /** Promo otomatis terbaik untuk paket ini (diskon terbesar). */
    public static function bestPromo(Plan $plan, bool $isRenewal): ?Promo
    {
        $best = null;
        foreach (Promo::whereHas('plans', fn ($q) => $q->where('plans.id', $plan->id))->get() as $p) {
            if (!$p->isRunning()) continue;
            if ($p->renewal_only && !$isRenewal) continue;
            if ($best === null || $p->discountFor($plan->price) > $best->discountFor($plan->price)) {
                $best = $p;
            }
        }
        return $best;
    }

    /**
     * Hitung harga. Kode promo (jika diisi) menggantikan promo otomatis,
     * sama seperti perilaku di aplikasi.
     *
     * @return array{promo: ?Promo, label: ?string, discount: int, amount: int}
     */
    public static function quote(Plan $plan, bool $isRenewal, ?string $code = null): array
    {
        $promo = null;
        $label = null;
        $discount = 0;

        if ($code !== null && trim($code) !== '') {
            $c = PromoCode::where('code', strtoupper(trim($code)))->where('is_enabled', true)->first();
            if (!$c) {
                throw ValidationException::withMessages(['promo_code' => 'Kode promo tidak valid']);
            }
            $discount = min($plan->price, (int) round($plan->price * $c->discount_percent / 100));
            $label = $c->code;
        } elseif ($promo = self::bestPromo($plan, $isRenewal)) {
            $discount = $promo->discountFor($plan->price);
            $label = $promo->name;
        }

        return [
            'promo' => $promo,
            'label' => $discount > 0 ? $label : null,
            'discount' => $discount,
            'amount' => $plan->price - $discount,
        ];
    }
}
