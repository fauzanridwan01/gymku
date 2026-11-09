<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CheckIn;
use App\Services\FaceMatcher;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CheckInController extends Controller
{
    /** Riwayat check-in saya + ringkasan bulan ini. */
    public function index(Request $r): JsonResponse
    {
        $q = CheckIn::where('user_id', $r->user()->id);
        $rows = (clone $q)->orderByDesc('checked_in_at')->limit(200)->get();

        $monthStart = today()->startOfMonth();
        $month = (clone $q)->where('checked_in_at', '>=', $monthStart)
            ->where('checked_in_at', '<', $monthStart->copy()->addMonth())->get();

        return response()->json([
            'visits_this_month' => $month->count(),
            'active_days_this_month' => $month->map(fn ($c) => $c->checked_in_at->toDateString())->unique()->count(),
            'items' => $rows->map->toApi()->values(),
        ]);
    }

    /**
     * Check-in mandiri. Jika `photo` dikirim dan wajah sudah terdaftar, dicocokkan
     * lewat FaceMatcher (algoritma tim lain; selama belum ada, pencocokan dilewati).
     */
    public function store(Request $r, FaceMatcher $matcher): JsonResponse
    {
        $r->validate(['photo' => 'nullable|image|max:4096']);
        $user = $r->user();

        if ($why = $user->entryDeniedReason()) {
            abort(403, $why);
        }
        if ($r->hasFile('photo') && $user->faceTemplate) {
            $score = $matcher->match($r->file('photo'), $user->faceTemplate);
            abort_if($score !== null && $score < FaceMatcher::THRESHOLD, 403, 'Wajah tidak cocok');
        }
        abort_if(
            CheckIn::where('user_id', $user->id)->where('checked_in_at', '>', now()->subMinutes(2))->exists(),
            409, 'Kamu baru saja check-in'
        );

        $c = CheckIn::create(['user_id' => $user->id, 'checked_in_at' => now(), 'method' => 'face'])->refresh();
        return response()->json($c->toApi(), 201);
    }
}
