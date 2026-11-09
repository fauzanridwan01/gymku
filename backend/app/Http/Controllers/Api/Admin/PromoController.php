<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Models\Promo;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PromoController extends Controller
{
    public function index(): JsonResponse
    {
        $rows = Promo::with('plans')->orderByDesc('id')->get();
        return response()->json(['items' => $rows->map->toApi()->values()]);
    }

    public function store(Request $r): JsonResponse
    {
        [$data, $planIds] = $this->payload($r);
        $promo = Promo::create($data)->refresh(); // muat nilai bawaan database
        $promo->plans()->sync($planIds);
        ActivityLogger::log('promo', 'Admin membuat promo', $promo->name, $r->user()->id);
        return response()->json($promo->load('plans')->toApi(), 201);
    }

    public function update(Request $r, int $id): JsonResponse
    {
        $promo = Promo::findOrFail($id);
        [$data, $planIds] = $this->payload($r, $promo->used);
        $promo->update($data);
        $promo->plans()->sync($planIds);
        ActivityLogger::log('promo', 'Admin mengubah promo', $promo->name, $r->user()->id);
        return response()->json($promo->load('plans')->toApi());
    }

    /** Hentikan promo sekarang juga. */
    public function end(Request $r, int $id): JsonResponse
    {
        $promo = Promo::findOrFail($id);
        $promo->update(['ended_manually' => true]);
        ActivityLogger::log('promo', 'Admin menghentikan promo', $promo->name, $r->user()->id);
        return response()->json($promo->load('plans')->toApi());
    }

    public function setEnabled(Request $r, int $id): JsonResponse
    {
        $d = $r->validate(['enabled' => 'required|boolean']);
        $promo = Promo::findOrFail($id);
        $promo->update(['is_enabled' => (bool) $d['enabled']]);
        return response()->json($promo->load('plans')->toApi());
    }

    private function payload(Request $r, int $minQuota = 1): array
    {
        $d = $r->validate([
            'name' => ['required', 'string', 'max:120'],
            'type' => ['required', Rule::in(['percent', 'nominal'])],
            'value' => ['required', 'integer', 'min:1', Rule::when($r->input('type') === 'percent', 'max:100')],
            'quota' => ['required', 'integer', 'min:' . max(1, $minQuota)],
            'plan_codes' => ['required', 'array', 'min:1'],
            'plan_codes.*' => ['string', Rule::exists('plans', 'code')],
            'renewal_only' => ['boolean'],
            'starts_on' => ['required', 'date'],
            'ends_on' => ['required', 'date', 'after_or_equal:starts_on'],
        ]);

        $planIds = Plan::whereIn('code', $d['plan_codes'])->pluck('id')->all();
        unset($d['plan_codes']);
        $d['name'] = trim($d['name']);
        $d['renewal_only'] = (bool) ($d['renewal_only'] ?? false);

        return [$d, $planIds];
    }
}
