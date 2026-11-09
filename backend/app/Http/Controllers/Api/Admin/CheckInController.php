<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\CheckIn;
use App\Models\User;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CheckInController extends Controller
{
    /** Admin mencatat check-in member (hasil scan wajah atau manual). */
    public function store(Request $r): JsonResponse
    {
        $d = $r->validate([
            'user_id' => ['required', Rule::exists('users', 'id')->where('role', 'member')],
            'method' => ['nullable', Rule::in(['face', 'manual'])],
        ]);
        $member = User::findOrFail($d['user_id']);
        $method = $d['method'] ?? 'face';

        if ($why = $member->entryDeniedReason()) {
            abort(403, $why);
        }
        abort_if(
            CheckIn::where('user_id', $member->id)->where('checked_in_at', '>', now()->subMinutes(2))->exists(),
            409, $member->name . ' baru saja check-in'
        );

        $c = CheckIn::create([
            'user_id' => $member->id, 'checked_in_at' => now(), 'method' => $method,
            'recorded_by' => $r->user()->id,
        ])->refresh();

        ActivityLogger::log('checkin',
            $method === 'face' ? 'Admin mengizinkan masuk (scan wajah)' : 'Admin check-in manual member',
            $member->member_code . ' · ' . $member->name, $r->user()->id);

        return response()->json($c->toApi(), 201);
    }
}
