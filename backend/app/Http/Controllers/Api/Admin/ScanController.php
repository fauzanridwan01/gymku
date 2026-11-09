<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\FaceMatcher;
use App\Services\MemberStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Layar Scan admin: kenali wajah, lalu aplikasi memanggil POST /admin/checkins. */
class ScanController extends Controller
{
    public function recognize(Request $r, FaceMatcher $matcher): JsonResponse
    {
        $r->validate(['photo' => 'required|image|max:4096']);

        $u = $matcher->identify($r->file('photo'));
        if (!$u) {
            return response()->json(['message' => 'Wajah tidak dikenali atau modul pengenalan wajah belum diisi.'], 404);
        }
        $u->loadMissing('membership');
        return response()->json([
            'member' => ['id' => $u->id, 'name' => $u->name, 'member_code' => $u->member_code],
            'status' => MemberStatus::of($u),
            'denied_reason' => $u->entryDeniedReason(),
        ]);
    }
}
