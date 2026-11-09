<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LogController extends Controller
{
    /** Log aktivitas: ?kind=&limit= */
    public function index(Request $r): JsonResponse
    {
        $d = $r->validate(['kind' => 'nullable|string|max:20', 'limit' => 'nullable|integer|min:1|max:200']);
        $q = ActivityLog::orderByDesc('id');
        if (!empty($d['kind'])) $q->where('kind', $d['kind']);

        return response()->json(['items' => $q->limit($d['limit'] ?? 50)->get()->map->toApi()->values()]);
    }

    /** Semua pembayaran berhasil (terbaru dulu). */
    public function transactions(Request $r): JsonResponse
    {
        $d = $r->validate(['limit' => 'nullable|integer|min:1|max:200']);
        $rows = Transaction::where('status', 'paid')->orderByDesc('paid_at')->limit($d['limit'] ?? 50)->get();
        $users = User::whereIn('id', $rows->pluck('user_id'))->get()->keyBy('id');

        return response()->json(['items' => $rows->map(fn ($t) => $t->toApi() + [
            'member_name' => $users->get($t->user_id)?->name,
            'member_code' => $users->get($t->user_id)?->member_code,
        ])->values()]);
    }
}
