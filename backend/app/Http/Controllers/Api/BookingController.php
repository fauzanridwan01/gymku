<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\GymClass;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BookingController extends Controller
{
    /** Kelas yang saya booking (yang belum lewat lebih dulu). */
    public function index(Request $r): JsonResponse
    {
        $classes = GymClass::withCount('bookings')
            ->whereIn('id', Booking::where('user_id', $r->user()->id)->select('gym_class_id'))
            ->orderBy('starts_at')->get();

        return response()->json([
            'items' => $classes->map(fn ($c) => $c->toApi($c->bookings_count, true))->values(),
        ]);
    }

    public function store(Request $r): JsonResponse
    {
        $d = $r->validate(['class_id' => 'required|integer|exists:gym_classes,id']);
        $user = $r->user();

        abort_if($user->is_blocked, 403, 'Akun kamu diblokir. Hubungi admin gym.');
        $m = $user->membership;
        abort_unless($m && $m->isActive(), 422, 'Membership kamu tidak aktif');
        abort_if($m->isFrozen(), 422, 'Booking dijeda selama membership dibekukan');

        $result = DB::transaction(function () use ($user, $m, $d) {
            // Kunci baris kelas agar dua booking bersamaan tidak melewati kapasitas.
            $class = GymClass::whereKey($d['class_id'])->lockForUpdate()->firstOrFail();

            abort_unless(GymClass::whereKey($class->id)->where('starts_at', '>', now())->exists(), 422, 'Kelas sudah dimulai');
            abort_if(Booking::where('user_id', $user->id)->where('gym_class_id', $class->id)->exists(), 409, 'Kamu sudah booking kelas ini');

            $count = Booking::where('gym_class_id', $class->id)->count();
            abort_if($count >= $class->capacity, 422, 'Kelas sudah penuh');

            $f = $m->currentFreeze();
            $date = $class->starts_at->toDateString();
            abort_if($f && $date >= $f->starts_on->toDateString() && $date <= $f->ends_on->toDateString(), 422,
                'Tanggal kelas berada dalam masa pembekuan');

            Booking::create(['user_id' => $user->id, 'gym_class_id' => $class->id]);
            return $class->toApi($count + 1, true);
        });

        return response()->json($result, 201);
    }

    /** Batalkan booking; maksimal 1 jam sebelum kelas dimulai. */
    public function destroy(Request $r, int $classId): JsonResponse
    {
        $booking = Booking::where('user_id', $r->user()->id)->where('gym_class_id', $classId)->firstOrFail();

        $ok = GymClass::whereKey($classId)->where('starts_at', '>=', now()->addMinutes(60))->exists();
        abort_unless($ok, 422, 'Pembatalan maksimal 1 jam sebelum kelas dimulai');

        $booking->delete();
        return response()->json(['message' => 'Booking dibatalkan.']);
    }
}
