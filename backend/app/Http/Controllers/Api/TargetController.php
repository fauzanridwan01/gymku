<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CheckIn;
use App\Models\Target;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TargetController extends Controller
{
    /** Target + progres, titik kunjungan minggu ini, dan streak mingguan. */
    public function index(Request $r): JsonResponse
    {
        $u = $r->user();
        $targets = Target::where('user_id', $u->id)->orderBy('id')->get();

        $weekly = $targets->firstWhere('period', 'weekly');
        $current = $weekly ? $this->streak($u, $weekly->count) : 0;
        if ($current > $u->best_streak) {
            $u->update(['best_streak' => $current]);
        }

        $ws = today()->startOfWeek();
        $dots = [];
        for ($i = 0; $i < 7; $i++) {
            $d = $ws->copy()->addDays($i);
            $dots[] = $this->visits($u, $d, $d->copy()->addDay()) > 0;
        }

        return response()->json([
            'current_streak_weeks' => $current,
            'best_streak_weeks' => max($u->best_streak, $current),
            'week_dots' => $dots,
            'items' => $targets->map(fn ($t) => $this->toApi($t, $u))->values(),
        ]);
    }

    public function store(Request $r): JsonResponse
    {
        $u = $r->user();
        $d = $r->validate([
            'name' => ['required', 'string', 'max:100'],
            'period' => ['required', Rule::in(['weekly', 'monthly'])],
            'count' => ['required', 'integer', 'min:1', 'max:' . ($r->input('period') === 'weekly' ? 7 : 31)],
            'days' => ['nullable', 'array'],
            'days.*' => ['integer', 'between:1,7'],
            'reminder' => ['boolean'],
            'reminder_time' => ['nullable', 'date_format:H:i'],
        ]);

        $m = $u->membership;
        abort_unless($m && $m->isActive(), 422, 'Target hanya untuk member aktif');
        abort_if(
            Target::where('user_id', $u->id)->where('period', $d['period'])->exists(), 422,
            $d['period'] === 'weekly'
                ? 'Kamu sudah punya target mingguan. Hapus dulu untuk membuat yang baru.'
                : 'Kamu sudah punya target bulanan. Hapus dulu untuk membuat yang baru.'
        );

        $t = Target::create([
            'user_id' => $u->id,
            'name' => trim($d['name']),
            'period' => $d['period'],
            'count' => $d['count'],
            'days' => $d['period'] === 'weekly' ? array_values(array_unique($d['days'] ?? [])) : [],
            'reminder' => (bool) ($d['reminder'] ?? false),
            'reminder_time' => $d['reminder_time'] ?? null,
        ])->refresh();

        return response()->json($this->toApi($t, $u), 201);
    }

    public function destroy(Request $r, int $id): JsonResponse
    {
        Target::where('user_id', $r->user()->id)->findOrFail($id)->delete();
        return response()->json(['message' => 'Target dihapus.']);
    }

    private function toApi(Target $t, User $u): array
    {
        $n = today();
        [$from, $to] = $t->period === 'weekly'
            ? [$n->copy()->startOfWeek(), $n->copy()->startOfWeek()->addWeek()]
            : [$n->copy()->startOfMonth(), $n->copy()->startOfMonth()->addMonth()];

        return [
            'id' => $t->id,
            'name' => $t->name,
            'period' => $t->period,
            'count' => $t->count,
            'days' => $t->days ?? [],
            'reminder' => $t->reminder,
            'reminder_time' => $t->reminder_time ? substr($t->reminder_time, 0, 5) : null,
            'progress' => $this->visits($u, $from, $to),
        ];
    }

    private function visits(User $u, $from, $to): int
    {
        return CheckIn::where('user_id', $u->id)->where('checked_in_at', '>=', $from)->where('checked_in_at', '<', $to)->count();
    }

    /** Jumlah minggu berturut-turut (sampai minggu ini) yang memenuhi target mingguan. */
    private function streak(User $u, int $goal): int
    {
        if ($goal <= 0) return 0;
        $ws = today()->startOfWeek();
        $perWeek = CheckIn::where('user_id', $u->id)->where('checked_in_at', '>=', $ws->copy()->subWeeks(260))
            ->get(['checked_in_at'])
            ->groupBy(fn ($c) => $c->checked_in_at->copy()->startOfWeek()->toDateString())
            ->map->count();

        $streak = ($perWeek[$ws->toDateString()] ?? 0) >= $goal ? 1 : 0;
        for ($i = 1; $i < 260; $i++) {
            if (($perWeek[$ws->copy()->subWeeks($i)->toDateString()] ?? 0) >= $goal) {
                $streak++;
            } else {
                break;
            }
        }
        return $streak;
    }
}
