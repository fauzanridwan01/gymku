<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FreezeRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/** Permintaan bekukan / buka bekuan membership (disetujui admin). */
class FreezeController extends Controller
{
    /** Status pembekuan + permintaan yang sedang menunggu. */
    public function show(Request $r): JsonResponse
    {
        $m = $r->user()->membership;
        $pending = FreezeRequest::where('user_id', $r->user()->id)->where('status', 'pending')->latest('id')->first();

        return response()->json([
            'membership' => $m?->toApi(),
            'max_freeze_days' => \App\Models\Membership::MAX_FREEZE_DAYS,
            'pending_request' => $pending?->toApi(),
        ]);
    }

    public function index(Request $r): JsonResponse
    {
        $rows = FreezeRequest::where('user_id', $r->user()->id)->orderByDesc('id')->get();
        return response()->json(['items' => $rows->map->toApi()->values()]);
    }

    public function requestFreeze(Request $r): JsonResponse
    {
        $d = $r->validate([
            'start' => ['required', 'date_format:Y-m-d'],
            'days' => ['required', 'integer', 'min:1', 'max:' . \App\Models\Membership::MAX_FREEZE_DAYS],
            'reason' => ['required', 'string', 'max:255'],
        ]);
        $u = $r->user();
        $m = $u->membership;

        abort_unless($m && $m->isActive(), 422, 'Membership tidak aktif');
        abort_if($m->currentFreeze(), 422, 'Membership sudah dibekukan / dijadwalkan beku');
        abort_if($this->hasPending($u->id), 422, 'Masih ada permintaan yang menunggu persetujuan admin');
        abort_if($d['days'] > $m->freezeDaysAvailable(), 422, 'Sisa jatah beku hanya ' . $m->freezeDaysAvailable() . ' hari');
        abort_if(Carbon::parse($d['start'])->startOfDay()->lt(today()), 422, 'Tanggal mulai tidak boleh di masa lalu');
        abort_if(trim($d['reason']) === '', 422, 'Alasan pembekuan wajib diisi');

        $req = FreezeRequest::create([
            'user_id' => $u->id, 'type' => 'freeze', 'reason' => trim($d['reason']),
            'since' => $d['start'], 'days' => $d['days'], 'status' => 'pending',
        ])->refresh();

        return response()->json($req->toApi(), 201);
    }

    public function requestUnfreeze(Request $r): JsonResponse
    {
        $u = $r->user();
        $m = $u->membership;
        $f = $m?->currentFreeze();

        abort_unless($m && $f, 422, 'Tidak ada pembekuan aktif');
        abort_if($this->hasPending($u->id), 422, 'Masih ada permintaan yang menunggu persetujuan admin');

        $scheduled = today()->lt($f->starts_on);
        $req = FreezeRequest::create([
            'user_id' => $u->id, 'type' => 'unfreeze', 'reason' => $f->reason,
            'since' => $f->starts_on,
            'days' => $scheduled ? $f->length() : max(0, (int) today()->diffInDays($f->ends_on, false) + 1),
            'status' => 'pending',
        ])->refresh();

        return response()->json($req->toApi(), 201);
    }

    private function hasPending(int $userId): bool
    {
        return FreezeRequest::where('user_id', $userId)->where('status', 'pending')->exists();
    }
}
