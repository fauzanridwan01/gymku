<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Services\Pricing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlanController extends Controller
{
    /** Paket aktif + promo otomatis yang berlaku untuk pengguna ini. */
    public function index(Request $r): JsonResponse
    {
        $renewal = $r->user()->membership?->isActive() ?? false;

        $items = Plan::where('is_enabled', true)->orderBy('days')->get()->map(function (Plan $p) use ($renewal) {
            $q = Pricing::quote($p, $renewal);
            return $p->toApi() + [
                'promo' => $q['promo'] ? [
                    'id' => $q['promo']->id,
                    'name' => $q['promo']->name,
                    'discount' => $q['discount'],
                    'final_price' => $q['amount'],
                ] : null,
            ];
        });

        return response()->json(['items' => $items]);
    }
}
