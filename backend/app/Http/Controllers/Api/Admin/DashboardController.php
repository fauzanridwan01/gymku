<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\CheckIn;
use App\Models\Transaction;
use App\Models\User;
use App\Services\MemberStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    public function dashboard(): JsonResponse
    {
        $members = User::with('membership')->where('role', 'member')->get();
        $status = $members->mapWithKeys(fn ($u) => [$u->id => MemberStatus::of($u)]);

        $expiring = $members->filter(fn ($u) => $status[$u->id] === 'expiring')->map(fn ($u) => [
            'id' => $u->id, 'name' => $u->name, 'member_code' => $u->member_code,
            'remaining_days' => $u->membership->remainingDays(),
        ])->values();

        return response()->json([
            'active_members' => $status->filter(fn ($s) => MemberStatus::isLive($s))->count(),
            'blocked_members' => $members->where('is_blocked', true)->count(),
            'new_members_today' => $members->filter(fn ($u) => $u->joined_at && $u->joined_at->isSameDay(today()))->count(),
            'expiring_members' => $expiring,
            'visits_today' => $this->visits(today(), today()->addDay()),
            'visits_yesterday' => $this->visits(today()->subDay(), today()),
            'revenue_30' => $this->revenue(today()->subDays(29), today()->addDay()),
            'revenue_prev_30' => $this->revenue(today()->subDays(59), today()->subDays(29)),
            'hourly_buckets' => $this->hourlyBuckets(),
            'recent_logs' => ActivityLog::orderByDesc('id')->limit(6)->get()->map->toApi()->values(),
        ]);
    }

    /** Laporan bulanan: ?month=YYYY-MM (default bulan ini). */
    public function reports(Request $r): JsonResponse
    {
        $r->validate(['month' => 'nullable|date_format:Y-m', 'inactive_days' => 'nullable|integer|min:1|max:365']);
        $m = $r->filled('month') ? Carbon::createFromFormat('Y-m-d', $r->month . '-01')->startOfDay() : today()->startOfMonth();
        $next = $m->copy()->addMonth();
        $prev = $m->copy()->subMonth();

        $weekly = array_fill(0, 4, 0);
        foreach (CheckIn::where('checked_in_at', '>=', $m)->where('checked_in_at', '<', $next)->get(['id', 'checked_in_at']) as $c) {
            $weekly[min(3, intdiv($c->checked_in_at->day - 1, 7))]++;
        }

        return response()->json([
            'months' => collect(range(0, 5))->map(fn ($i) => today()->startOfMonth()->subMonths($i)->format('Y-m'))->all(),
            'month' => $m->format('Y-m'),
            'visits' => array_sum($weekly),
            'visits_prev_month' => $this->visits($prev, $m),
            'revenue' => $this->revenue($m, $next),
            'revenue_prev_month' => $this->revenue($prev, $m),
            'weekly_visits' => $weekly,
            'hourly_buckets' => $this->hourlyBuckets(),
            'inactive_members' => $this->inactive($r->integer('inactive_days', 30)),
        ]);
    }

    private function visits(Carbon $from, Carbon $to): int
    {
        return CheckIn::where('checked_in_at', '>=', $from)->where('checked_in_at', '<', $to)->count();
    }

    private function revenue(Carbon $from, Carbon $to): int
    {
        return (int) Transaction::where('status', 'paid')->where('paid_at', '>=', $from)->where('paid_at', '<', $to)->sum('amount');
    }

    /** Kunjungan 14 hari terakhir per 2 jam, jam 06..20 (8 kolom). */
    private function hourlyBuckets(): array
    {
        $out = array_fill(0, 8, 0);
        foreach (CheckIn::where('checked_in_at', '>=', today()->subDays(13))->get(['id', 'checked_in_at']) as $c) {
            $out[max(0, min(7, intdiv($c->checked_in_at->hour - 6, 2)))]++;
        }
        return $out;
    }

    /** Member aktif yang sudah >= $days hari tidak datang (paling lama dulu). */
    private function inactive(int $days): array
    {
        $last = CheckIn::selectRaw('user_id, MAX(checked_in_at) as last_at')->groupBy('user_id')->pluck('last_at', 'user_id');
        $out = [];
        foreach (User::with('membership')->where('role', 'member')->get() as $u) {
            if (!MemberStatus::isLive(MemberStatus::of($u))) continue;
            $d = isset($last[$u->id]) ? (int) Carbon::parse($last[$u->id])->startOfDay()->diffInDays(today()) : 999;
            if ($d >= $days) {
                $out[] = ['id' => $u->id, 'name' => $u->name, 'member_code' => $u->member_code, 'days' => $d];
            }
        }
        usort($out, fn ($a, $b) => $b['days'] <=> $a['days']);
        return $out;
    }
}
