<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Freeze;
use App\Models\FreezeRequest;
use App\Models\GymClass;
use App\Models\Membership;
use App\Models\User;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class FreezeRequestController extends Controller
{
    /** ?status=pending|approved|rejected  &type=freeze|unfreeze */
    public function index(Request $r): JsonResponse
    {
        $r->validate([
            'status' => ['nullable', Rule::in(['pending', 'approved', 'rejected'])],
            'type' => ['nullable', Rule::in(['freeze', 'unfreeze'])],
        ]);
        $q = FreezeRequest::query()->orderByDesc('id');
        foreach (['status', 'type'] as $f) {
            if ($r->filled($f)) $q->where($f, $r->$f);
        }
        return response()->json(['items' => $q->limit(200)->get()->map(fn ($x) => $x->toApi(true))->values()]);
    }

    public function decide(Request $r, int $id): JsonResponse
    {
        $d = $r->validate(['approve' => 'required|boolean', 'note' => 'nullable|string|max:255']);
        $approve = (bool) $d['approve'];

        $result = DB::transaction(function () use ($r, $id, $d, $approve) {
            $req = FreezeRequest::whereKey($id)->lockForUpdate()->firstOrFail();
            abort_unless($req->status === 'pending', 409, 'Permintaan sudah diproses');

            $member = User::findOrFail($req->user_id);
            if ($approve) {
                $req->type === 'freeze' ? $this->applyFreeze($member, $req) : $this->applyUnfreeze($member);
            }

            $req->update([
                'status' => $approve ? 'approved' : 'rejected',
                'decided_by' => $r->user()->id, 'decided_at' => now(), 'decision_note' => $d['note'] ?? null,
            ]);

            ActivityLogger::log('freeze', match ([$req->type, $approve]) {
                ['freeze', true] => 'Admin menyetujui pembekuan',
                ['freeze', false] => 'Admin menolak pembekuan',
                ['unfreeze', true] => 'Admin menyetujui buka bekuan',
                default => 'Admin menolak buka bekuan',
            }, $member->member_code . ' · ' . $member->name, $r->user()->id);

            return $req->fresh();
        });

        return response()->json($result->toApi(true));
    }

    private function applyFreeze(User $member, FreezeRequest $req): void
    {
        $m = $member->membership;
        abort_unless($m && $m->isActive(), 422, 'Membership tidak aktif');
        abort_if($m->currentFreeze(), 422, 'Membership sudah dibekukan / dijadwalkan beku');
        abort_if($req->days <= 0, 422, 'Lama pembekuan tidak valid');
        abort_if($req->days > $m->freezeDaysAvailable(), 422, 'Sisa jatah beku hanya ' . $m->freezeDaysAvailable() . ' hari');

        $start = $req->since->copy()->startOfDay();
        abort_if($start->lt(today()), 422, 'Tanggal mulai permintaan sudah lewat');
        $end = $start->copy()->addDays($req->days - 1);

        // Booking yang jatuh pada masa pembekuan dibatalkan.
        $classIds = GymClass::where('starts_at', '>=', $start)->where('starts_at', '<', $end->copy()->addDay())->pluck('id');
        Booking::where('user_id', $member->id)->whereIn('gym_class_id', $classIds)->delete();

        Freeze::create([
            'membership_id' => $m->id, 'starts_on' => $start, 'ends_on' => $end, 'reason' => $req->reason,
            'remaining_at_start' => max(0, (int) $start->diffInDays($m->ends_on, false)),
        ]);
        // Masa pembekuan tidak mengurangi masa aktif: tanggal berakhir ikut mundur.
        $m->update([
            'freeze_days_used' => $m->freeze_days_used + $req->days,
            'ends_on' => $m->ends_on->copy()->addDays($req->days),
        ]);
    }

    private function applyUnfreeze(User $member): void
    {
        $m = $member->membership;
        $f = $m?->currentFreeze();
        abort_unless($m && $f, 422, 'Tidak ada pembekuan aktif');

        $unused = today()->lt($f->starts_on)
            ? $f->length()
            : max(0, (int) today()->diffInDays($f->ends_on, false) + 1);

        $m->update([
            'ends_on' => $m->ends_on->copy()->subDays($unused),
            'freeze_days_used' => max(0, $m->freeze_days_used - $unused),
        ]);
        $f->delete();
    }
}
