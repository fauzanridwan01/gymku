<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\BlockRecord;
use App\Models\CheckIn;
use App\Models\FreezeRequest;
use App\Models\Transaction;
use App\Models\User;
use App\Services\ActivityLogger;
use App\Services\MemberStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

class MemberController extends Controller
{
    /** Daftar / pencarian member. Dipakai juga oleh pemilih target di Buat Informasi. */
    public function index(Request $r): JsonResponse
    {
        $d = $r->validate([
            'q' => 'nullable|string|max:100',
            'status' => ['nullable', Rule::in(array_keys(MemberStatus::LABELS))],
            'gender' => 'nullable|in:Laki-laki,Perempuan',
            'limit' => 'nullable|integer|min:1|max:200',
        ]);

        $q = User::with('membership')->where('role', 'member')->orderBy('name');
        if (!empty($d['q'])) {
            $term = '%' . str_replace(['%', '_'], ['\%', '\_'], mb_strtolower($d['q'])) . '%';
            $q->where(fn ($w) => $w->whereRaw('LOWER(name) LIKE ?', [$term])
                ->orWhereRaw('LOWER(email) LIKE ?', [$term])
                ->orWhereRaw('LOWER(member_code) LIKE ?', [$term]));
        }
        if (!empty($d['gender'])) $q->where('gender', $d['gender']);

        $last = CheckIn::selectRaw('user_id, MAX(checked_in_at) as last_at')->groupBy('user_id')->pluck('last_at', 'user_id');

        $items = $q->get()
            ->map(fn (User $u) => $this->row($u, $last[$u->id] ?? null))
            ->when(!empty($d['status']), fn ($c) => $c->where('status', $d['status']))
            ->take($d['limit'] ?? 30)->values();

        return response()->json(['items' => $items]);
    }

    public function show(int $id): JsonResponse
    {
        $u = User::with('membership')->where('role', 'member')->findOrFail($id);
        $monthStart = today()->startOfMonth();

        $checkins = CheckIn::where('user_id', $u->id)->orderByDesc('checked_in_at');
        $last = (clone $checkins)->value('checked_in_at');

        $block = BlockRecord::where('user_id', $u->id)->where('active', true)->latest('id')->first();

        return response()->json([
            'member' => $this->row($u, $last) + ['birth_date' => $u->birth_date?->toDateString(), 'joined_at' => $u->joined_at?->toDateString()],
            'membership' => $u->membership?->toApi(),
            'visits_this_month' => CheckIn::where('user_id', $u->id)->where('checked_in_at', '>=', $monthStart)
                ->where('checked_in_at', '<', $monthStart->copy()->addMonth())->count(),
            'checkins' => (clone $checkins)->limit(20)->get()->map->toApi()->values(),
            'transactions' => Transaction::where('user_id', $u->id)->where('status', 'paid')
                ->orderByDesc('paid_at')->limit(10)->get()->map->toApi()->values(),
            'active_block' => $block?->toApi($u, $block->blocked_by ? User::find($block->blocked_by) : null),
            'freeze_requests' => FreezeRequest::where('user_id', $u->id)->orderByDesc('id')->limit(5)->get()
                ->map(fn ($x) => $x->toApi())->values(),
        ]);
    }

    public function block(Request $r, int $id): JsonResponse
    {
        $d = $r->validate(['reason' => 'required|string|max:255']);
        $u = User::where('role', 'member')->findOrFail($id);
        abort_if($u->is_blocked, 422, 'Member sudah diblokir');

        $u->update(['is_blocked' => true]);
        BlockRecord::create(['user_id' => $u->id, 'reason' => trim($d['reason']), 'blocked_by' => $r->user()->id, 'active' => true]);
        $u->tokens()->delete(); // keluarkan dari semua perangkat

        ActivityLogger::log('block', 'Admin memblokir member', $u->member_code . ' · ' . $u->name, $r->user()->id);
        return response()->json($this->row($u->refresh()->load('membership'), null));
    }

    public function unblock(Request $r, int $id): JsonResponse
    {
        $d = $r->validate(['note' => 'nullable|string|max:255']);
        $u = User::where('role', 'member')->findOrFail($id);
        $active = BlockRecord::where('user_id', $u->id)->where('active', true);
        abort_unless($u->is_blocked && $active->exists(), 422, 'Member tidak sedang diblokir');

        $active->update([
            'active' => false,
            'unblock_note' => isset($d['note']) && trim($d['note']) !== '' ? trim($d['note']) : null,
            'unblocked_at' => now(),
        ]);
        $u->update(['is_blocked' => false]);

        ActivityLogger::log('unblock', 'Admin membuka blokir member', $u->member_code . ' · ' . $u->name, $r->user()->id);
        return response()->json($this->row($u->refresh()->load('membership'), null));
    }

    /** Daftar blokir: yang masih aktif dan yang sudah dibuka kembali. */
    public function blocks(): JsonResponse
    {
        $rows = BlockRecord::orderByDesc('id')->get();
        $users = User::whereIn('id', $rows->pluck('user_id')->merge($rows->pluck('blocked_by'))->filter())->get()->keyBy('id');
        $map = fn ($b) => $b->toApi($users->get($b->user_id), $users->get($b->blocked_by));

        return response()->json([
            'active' => $rows->where('active', true)->map($map)->values(),
            'reopened' => $rows->where('active', false)->map($map)->values(),
        ]);
    }

    private function row(User $u, $lastVisit): array
    {
        $status = MemberStatus::of($u);
        return [
            'id' => $u->id,
            'name' => $u->name,
            'email' => $u->email,
            'member_code' => $u->member_code,
            'gender' => $u->gender,
            'phone' => $u->phone,
            'is_blocked' => $u->is_blocked,
            'has_face' => $u->faceTemplate()->exists(),
            'status' => $status,
            'status_label' => MemberStatus::LABELS[$status],
            'remaining_days' => $u->membership?->remainingDays(),
            'last_visit_at' => $lastVisit ? Carbon::parse($lastVisit)->toIso8601String() : null,
        ];
    }
}
