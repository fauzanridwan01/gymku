<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Membership;
use App\Models\Plan;
use App\Models\Promo;
use App\Models\Transaction;
use App\Services\ActivityLogger;
use App\Services\Pricing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * Checkout. Pembayaran QRIS DISIMULASIKAN: endpoint simulate-pay berperan
 * sebagai webhook payment gateway. Ganti dengan webhook asli bila perlu.
 */
class OrderController extends Controller
{
    private const EXPIRY_MINUTES = 15;

    public function store(Request $r): JsonResponse
    {
        $d = $r->validate([
            'plan_code' => 'required|string',
            'promo_code' => 'nullable|string|max:30',
        ]);
        $user = $r->user();
        abort_if($user->is_blocked, 403, 'Akun Anda diblokir.');

        $plan = Plan::where('code', $d['plan_code'])->where('is_enabled', true)->first();
        if (!$plan) {
            throw ValidationException::withMessages(['plan_code' => 'Paket tidak tersedia.']);
        }

        $renewal = $user->membership?->isActive() ?? false;
        $q = Pricing::quote($plan, $renewal, $d['promo_code'] ?? null);

        $t = DB::transaction(function () use ($user, $plan, $q) {
            // Pesanan lama yang belum dibayar dibatalkan; satu pesanan aktif per user.
            Transaction::where('user_id', $user->id)->where('status', 'pending')->update(['status' => 'cancelled']);

            $t = Transaction::create([
                'code' => 'TMP-' . Str::random(12),
                'user_id' => $user->id,
                'plan_id' => $plan->id,
                'plan_name' => 'Premium ' . $plan->name,
                'plan_days' => $plan->days,
                'method' => 'QRIS',
                'base_price' => $plan->price,
                'discount' => $q['discount'],
                'amount' => $q['amount'],
                'promo_id' => $q['promo']?->id,
                'promo_label' => $q['label'],
                'status' => 'pending',
                'expires_at' => now()->addMinutes(self::EXPIRY_MINUTES),
            ]);

            // Kode dari id; bila sudah terpakai (data lama), tambahkan akhiran acak agar tidak bentrok.
            $code = sprintf('TRX-%04d', $t->id);
            if (Transaction::where('code', $code)->where('id', '!=', $t->id)->exists()) {
                $code .= '-' . strtoupper(Str::random(4));
            }
            $t->update(['code' => $code]);

            return $t;
        });

        return response()->json($t->toApi(), 201);
    }

    public function show(Request $r, string $code): JsonResponse
    {
        $t = $this->mine($r, $code);
        return response()->json($t->toApi());
    }

    /** Perpanjang waktu bayar (tombol "buat ulang QR"). */
    public function refresh(Request $r, string $code): JsonResponse
    {
        $t = $this->mine($r, $code);
        if (!in_array($t->status, ['pending', 'expired'], true)) {
            abort(422, 'Pesanan tidak bisa diperbarui.');
        }
        $t->update(['status' => 'pending', 'expires_at' => now()->addMinutes(self::EXPIRY_MINUTES)]);
        return response()->json($t->toApi());
    }

    public function cancel(Request $r, string $code): JsonResponse
    {
        $t = $this->mine($r, $code);
        abort_unless($t->status === 'pending', 422, 'Hanya pesanan yang belum dibayar yang bisa dibatalkan.');
        $t->update(['status' => 'cancelled']);
        return response()->json($t->toApi());
    }

    /** SIMULASI webhook pembayaran QRIS. Hanya aktif jika services.gymku.simulate_pay (local/testing atau GYMKU_SIMULATE_PAY=true). */
    public function simulatePay(Request $r, string $code): JsonResponse
    {
        abort_unless(config('services.gymku.simulate_pay'), 404);

        $this->mine($r, $code); // sekaligus menandai kedaluwarsa bila perlu

        $result = DB::transaction(function () use ($r, $code) {
            $t = Transaction::where('code', $code)->where('user_id', $r->user()->id)->lockForUpdate()->firstOrFail();

            abort_if($t->status === 'paid', 409, 'Pembayaran sudah dikonfirmasi.');
            abort_unless($t->status === 'pending', 422, $t->status === 'expired' ? 'Waktu pembayaran habis.' : 'Pesanan tidak aktif.');

            $user = $r->user();
            $m = $user->membership;
            $active = $m && $m->isActive();
            $start = $active ? $m->ends_on->copy() : today();
            $end = $start->copy()->addDays($t->plan_days);

            if ($active) {
                $m->update(['ends_on' => $end, 'total_days' => $m->total_days + $t->plan_days]);
            } else {
                $m = Membership::updateOrCreate(['user_id' => $user->id], [
                    'plan_name' => 'Premium', 'starts_on' => today(), 'ends_on' => $end,
                    'total_days' => $t->plan_days, 'freeze_days_used' => 0,
                ]);
            }

            $t->update(['status' => 'paid', 'paid_at' => now(), 'period_start' => $start, 'period_end' => $end]);

            if ($t->promo_id) {
                Promo::where('id', $t->promo_id)->whereColumn('used', '<', 'quota')->increment('used');
            }
            if (!$user->joined_at) {
                $user->update(['joined_at' => today()]);
            }
            ActivityLogger::log('payment', 'Sistem mencatat pembayaran ' . $t->method,
                $user->name . ' · ' . $t->plan_name, $user->id);

            return [$t->fresh(), $m->fresh()];
        });

        return response()->json(['transaction' => $result[0]->toApi(), 'membership' => $result[1]->toApi()]);
    }

    /** Riwayat pembayaran berhasil milik user. */
    public function history(Request $r): JsonResponse
    {
        $rows = Transaction::where('user_id', $r->user()->id)->where('status', 'paid')
            ->orderByDesc('paid_at')->get();
        return response()->json(['items' => $rows->map->toApi()->values()]);
    }

    private function mine(Request $r, string $code): Transaction
    {
        $t = Transaction::where('code', $code)->where('user_id', $r->user()->id)->firstOrFail();

        // Perbandingan waktu dilakukan di database agar tidak bergantung pada zona waktu PHP.
        Transaction::whereKey($t->id)->where('status', 'pending')
            ->where('expires_at', '<', now())->update(['status' => 'expired']);

        return $t->refresh();
    }
}
