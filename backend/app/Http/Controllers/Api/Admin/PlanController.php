<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlanController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(['items' => Plan::orderBy('days')->get()->map->toApi()]);
    }

    public function updatePrice(Request $r, int $id): JsonResponse
    {
        $d = $r->validate(['price' => 'required|integer|min:50000']);
        $plan = Plan::findOrFail($id);
        if ($plan->price === (int) $d['price']) {
            return response()->json(['message' => 'Harga baru sama dengan harga sekarang'], 422);
        }
        $old = $plan->price;
        $plan->update(['price' => $d['price']]);
        ActivityLogger::log('price', 'Admin mengubah harga paket',
            "{$plan->name}: Rp {$old} → Rp {$plan->price}", $r->user()->id);
        return response()->json($plan->toApi());
    }

    public function setEnabled(Request $r, int $id): JsonResponse
    {
        $d = $r->validate(['enabled' => 'required|boolean']);
        $plan = Plan::findOrFail($id);
        $on = (bool) $d['enabled'];
        if (!$on && $plan->is_enabled && Plan::where('is_enabled', true)->count() <= 1) {
            return response()->json(['message' => 'Minimal satu paket harus aktif'], 422);
        }
        $plan->update(['is_enabled' => $on]);
        ActivityLogger::log('price', $on ? 'Admin mengaktifkan paket' : 'Admin menonaktifkan paket',
            $plan->name, $r->user()->id);
        return response()->json($plan->toApi());
    }
}
