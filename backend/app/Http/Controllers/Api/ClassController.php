<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\GymClass;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ClassController extends Controller
{
    /** Jadwal kelas pada satu hari: ?date=YYYY-MM-DD (default hari ini). */
    public function index(Request $r): JsonResponse
    {
        $r->validate(['date' => 'nullable|date_format:Y-m-d']);
        $day = $r->filled('date') ? Carbon::parse($r->date)->startOfDay() : today();

        $rows = GymClass::withCount('bookings')
            ->where('starts_at', '>=', $day)->where('starts_at', '<', $day->copy()->addDay())
            ->orderBy('starts_at')->get();

        $mine = Booking::where('user_id', $r->user()->id)->whereIn('gym_class_id', $rows->pluck('id'))
            ->pluck('gym_class_id')->flip();

        return response()->json([
            'date' => $day->toDateString(),
            'items' => $rows->map(fn ($c) => $c->toApi($c->bookings_count, $mine->has($c->id)))->values(),
        ]);
    }
}
